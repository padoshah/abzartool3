#include "ops/document_ops.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <vector>

#include "core/error.h"
#include "ops/file_operations.h"
#include "util/fs.h"
#include "util/image_io.h"

#ifdef ABZAR_HAS_OPENCV
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#endif

namespace abzar::ops {
namespace {
void require_pixels(const ImageData& image) {
  if (image.rgba.size() != static_cast<std::size_t>(image.width) *
                               image.height * 4) {
    throw Error(ABZ_ERROR_INVALID_ARGUMENT,
                "Image has no decoded RGBA pixels");
  }
}
}  // namespace

void grayscale(ImageData& image) {
  require_pixels(image);
  for (std::size_t index = 0; index < image.rgba.size(); index += 4) {
    const auto gray = static_cast<unsigned char>(
        (77u * image.rgba[index] + 150u * image.rgba[index + 1] +
         29u * image.rgba[index + 2]) >> 8);
    image.rgba[index] = image.rgba[index + 1] = image.rgba[index + 2] = gray;
  }
}

void adjust_image(ImageData& image, double brightness, double contrast,
                  bool black_and_white) {
  require_pixels(image);
  brightness = std::clamp(brightness, -1.0, 1.0) * 255.0;
  contrast = std::clamp(contrast, .1, 3.0);
  for (std::size_t index = 0; index < image.rgba.size(); index += 4) {
    for (std::size_t channel = 0; channel < 3; ++channel) {
      auto value = (static_cast<double>(image.rgba[index + channel]) - 127.5) *
                       contrast +
                   127.5 + brightness;
      if (black_and_white) value = value >= 128 ? 255 : 0;
      image.rgba[index + channel] =
          static_cast<std::uint8_t>(std::clamp(value, 0.0, 255.0));
    }
  }
}

void magic_scan(ImageData& image) {
  require_pixels(image);
#ifndef ABZAR_HAS_OPENCV
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,
              "OpenCV scanner module is not compiled into this build");
#else
  cv::Mat rgba(static_cast<int>(image.height), static_cast<int>(image.width),
               CV_8UC4, image.rgba.data());
  cv::Mat gray, blurred, edges;
  cv::cvtColor(rgba, gray, cv::COLOR_RGBA2GRAY);
  cv::GaussianBlur(gray, blurred, cv::Size(5, 5), 0);
  cv::Canny(blurred, edges, 60, 180);
  std::vector<std::vector<cv::Point>> contours;
  cv::findContours(edges, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
  std::array<cv::Point2f, 4> corners{};
  double best_area = 0;
  for (const auto& contour : contours) {
    const auto perimeter = cv::arcLength(contour, true);
    std::vector<cv::Point> polygon;
    cv::approxPolyDP(contour, polygon, .02 * perimeter, true);
    const auto area = std::abs(cv::contourArea(polygon));
    if (polygon.size() != 4 || area <= best_area ||
        !cv::isContourConvex(polygon)) continue;
    best_area = area;
    for (std::size_t index = 0; index < 4; ++index) corners[index] = polygon[index];
  }
  if (best_area < static_cast<double>(image.width) * image.height * .08) {
    throw Error(ABZ_ERROR_VALIDATION, "No document boundary was detected");
  }
  auto sum = [](const cv::Point2f& point) { return point.x + point.y; };
  auto difference = [](const cv::Point2f& point) { return point.y - point.x; };
  const auto top_left = *std::min_element(corners.begin(), corners.end(),
      [&](const auto& left, const auto& right) { return sum(left) < sum(right); });
  const auto bottom_right = *std::max_element(corners.begin(), corners.end(),
      [&](const auto& left, const auto& right) { return sum(left) < sum(right); });
  const auto top_right = *std::min_element(corners.begin(), corners.end(),
      [&](const auto& left, const auto& right) { return difference(left) < difference(right); });
  const auto bottom_left = *std::max_element(corners.begin(), corners.end(),
      [&](const auto& left, const auto& right) { return difference(left) < difference(right); });
  const auto distance = [](const cv::Point2f& a, const cv::Point2f& b) {
    return std::hypot(a.x - b.x, a.y - b.y);
  };
  const auto width = std::max(1, static_cast<int>(std::max(
      distance(top_left, top_right), distance(bottom_left, bottom_right))));
  const auto height = std::max(1, static_cast<int>(std::max(
      distance(top_left, bottom_left), distance(top_right, bottom_right))));
  const std::array<cv::Point2f, 4> source = {top_left, top_right, bottom_right,
                                             bottom_left};
  const std::array<cv::Point2f, 4> target = {
      cv::Point2f(0, 0), cv::Point2f(static_cast<float>(width - 1), 0),
      cv::Point2f(static_cast<float>(width - 1),
                  static_cast<float>(height - 1)),
      cv::Point2f(0, static_cast<float>(height - 1))};
  const auto transform = cv::getPerspectiveTransform(source.data(), target.data());
  cv::Mat corrected;
  cv::warpPerspective(rgba, corrected, transform, cv::Size(width, height),
                      cv::INTER_CUBIC, cv::BORDER_REPLICATE);
  image.width = static_cast<std::uint32_t>(width);
  image.height = static_cast<std::uint32_t>(height);
  image.rgba.assign(corrected.data,
                    corrected.data + corrected.total() * corrected.elemSize());
#endif
}
}  // namespace abzar::ops

namespace abzar {
void process_scan_image(const std::filesystem::path& input,
                        const std::filesystem::path& output,
                        const std::string& format, bool perspective,
                        int filter, double brightness, double contrast) {
  auto image = images::decode(fs::read_bytes(input), format);
  if (perspective) ops::magic_scan(image);
  if (filter == 1) ops::grayscale(image);
  ops::adjust_image(image, brightness, contrast, filter == 2);
  std::vector<std::uint8_t> rgb;
  rgb.reserve(static_cast<std::size_t>(image.width) * image.height * 3);
  for (std::size_t index = 0; index < image.rgba.size(); index += 4) {
    rgb.insert(rgb.end(), {image.rgba[index], image.rgba[index + 1],
                           image.rgba[index + 2]});
  }
  if (output.extension() == ".jpg" || output.extension() == ".jpeg") {
    fs::write_bytes_atomic(output,
                           images::encode_jpeg(rgb, image.width, image.height, 94));
  } else {
    fs::write_bytes_atomic(output,
                           images::encode_png(rgb, image.width, image.height, 9));
  }
}
}  // namespace abzar
