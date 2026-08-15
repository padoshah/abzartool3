#include "util/image_io.h"
#include <algorithm>
#include <array>
#include <cstring>
#include <limits>
#include "core/error.h"
#include "stb/stb_image.h"
#include "stb/stb_image_write.h"
#include <zlib.h>
#ifdef ABZAR_HAS_WEBP
#include <webp/decode.h>
#include <webp/encode.h>
#endif
#ifdef ABZAR_HAS_TIFF
#include <tiffio.h>
#endif
namespace abzar::images {
namespace {
std::uint32_t be32(const std::uint8_t* p){return (std::uint32_t(p[0])<<24)|(std::uint32_t(p[1])<<16)|(std::uint32_t(p[2])<<8)|p[3];}
void put32(std::vector<std::uint8_t>& o,std::uint32_t v){o.push_back(static_cast<std::uint8_t>(v>>24));o.push_back(static_cast<std::uint8_t>(v>>16));o.push_back(static_cast<std::uint8_t>(v>>8));o.push_back(static_cast<std::uint8_t>(v));}
void chunk(std::vector<std::uint8_t>& o,const char type[4],const std::vector<std::uint8_t>& data){put32(o,static_cast<std::uint32_t>(data.size()));const auto start=o.size();o.insert(o.end(),type,type+4);o.insert(o.end(),data.begin(),data.end());put32(o,static_cast<std::uint32_t>(crc32(0,o.data()+start,static_cast<uInt>(4+data.size()))));}
int paeth(int a,int b,int c){const int p=a+b-c,pa=std::abs(p-a),pb=std::abs(p-b),pc=std::abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c;}
ImageData decode_png(const std::vector<std::uint8_t>& b){const std::uint8_t magic[]={137,80,78,71,13,10,26,10};if(b.size()<33||!std::equal(std::begin(magic),std::end(magic),b.begin()))throw Error(ABZ_ERROR_CORRUPT_INPUT,"Invalid PNG signature");std::uint32_t w=0,h=0;int depth=0,color=0;std::vector<std::uint8_t> idat;for(std::size_t p=8;p+12<=b.size();){const auto n=be32(b.data()+p);if(p+12+n>b.size())throw Error(ABZ_ERROR_CORRUPT_INPUT,"Truncated PNG chunk");const std::string t(reinterpret_cast<const char*>(b.data()+p+4),4);if(t=="IHDR"){w=be32(b.data()+p+8);h=be32(b.data()+p+12);depth=b[p+16];color=b[p+17];}else if(t=="IDAT")idat.insert(idat.end(),b.begin()+p+8,b.begin()+p+8+n);else if(t=="IEND")break;p+=12+n;}if(!w||!h||depth!=8||(color!=2&&color!=6))throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,"PNG decoder supports 8-bit RGB and RGBA images");const std::size_t channels=color==6?4:3,stride=std::size_t(w)*channels;std::vector<std::uint8_t> filtered((stride+1)*h);uLongf size=filtered.size();if(::uncompress(filtered.data(),&size,idat.data(),idat.size())!=Z_OK||size!=filtered.size())throw Error(ABZ_ERROR_CORRUPT_INPUT,"Invalid PNG image data");std::vector<std::uint8_t> raw(stride*h);for(std::uint32_t y=0;y<h;++y){const auto filter=filtered[y*(stride+1)];const auto* src=filtered.data()+y*(stride+1)+1;auto* dst=raw.data()+y*stride;for(std::size_t x=0;x<stride;++x){const int a=x>=channels?dst[x-channels]:0,bv=y?raw[(y-1)*stride+x]:0,c=(y&&x>=channels)?raw[(y-1)*stride+x-channels]:0;int value=src[x];if(filter==1)value+=a;else if(filter==2)value+=bv;else if(filter==3)value+=(a+bv)/2;else if(filter==4)value+=paeth(a,bv,c);else if(filter!=0)throw Error(ABZ_ERROR_CORRUPT_INPUT,"Unknown PNG filter");dst[x]=static_cast<std::uint8_t>(value&255);}}ImageData image;image.mime_type="image/png";image.encoded=b;image.width=w;image.height=h;image.rgba.resize(std::size_t(w)*h*4);for(std::size_t i=0,j=0;i<raw.size();i+=channels,j+=4){image.rgba[j]=raw[i];image.rgba[j+1]=raw[i+1];image.rgba[j+2]=raw[i+2];image.rgba[j+3]=channels==4?raw[i+3]:255;}return image;}
ImageData decode_stb(const std::vector<std::uint8_t>& bytes,const std::string& format){if(bytes.size()>static_cast<std::size_t>(std::numeric_limits<int>::max()))throw Error(ABZ_ERROR_OUT_OF_MEMORY,"Image is too large to decode");int width=0,height=0,channels=0;unsigned char* pixels=stbi_load_from_memory(bytes.data(),static_cast<int>(bytes.size()),&width,&height,&channels,4);if(!pixels||width<=0||height<=0)throw Error(ABZ_ERROR_CORRUPT_INPUT,stbi_failure_reason()?stbi_failure_reason():"Image decoding failed");ImageData image;image.mime_type=format=="jpg"||format=="jpeg"?"image/jpeg":format=="bmp"?"image/bmp":format=="gif"?"image/gif":"image/unknown";image.encoded=bytes;image.width=static_cast<std::uint32_t>(width);image.height=static_cast<std::uint32_t>(height);const auto size=static_cast<std::size_t>(width)*static_cast<std::size_t>(height)*4;image.rgba.assign(pixels,pixels+size);stbi_image_free(pixels);return image;}
void write_callback(void* context,void* data,int size){auto* output=static_cast<std::vector<std::uint8_t>*>(context);const auto* bytes=static_cast<std::uint8_t*>(data);output->insert(output->end(),bytes,bytes+size);}
#ifdef ABZAR_HAS_WEBP
ImageData decode_webp(const std::vector<std::uint8_t>& bytes){int width=0,height=0;std::uint8_t* pixels=WebPDecodeRGBA(bytes.data(),bytes.size(),&width,&height);if(!pixels||width<=0||height<=0)throw Error(ABZ_ERROR_CORRUPT_INPUT,"WebP decoding failed");ImageData image;image.mime_type="image/webp";image.encoded=bytes;image.width=static_cast<std::uint32_t>(width);image.height=static_cast<std::uint32_t>(height);image.rgba.assign(pixels,pixels+static_cast<std::size_t>(width)*height*4);WebPFree(pixels);return image;}
#endif
#ifdef ABZAR_HAS_TIFF
struct TiffMemory{const std::uint8_t* data;std::size_t size;toff_t offset;};
tmsize_t tiff_read(thandle_t handle,void* buffer,tmsize_t count){auto& memory=*static_cast<TiffMemory*>(handle);const auto available=memory.offset<memory.size?memory.size-static_cast<std::size_t>(memory.offset):0;const auto requested=count>0?static_cast<std::size_t>(count):0;const auto bytes=std::min(available,requested);std::memcpy(buffer,memory.data+memory.offset,bytes);memory.offset+=bytes;return static_cast<tmsize_t>(bytes);}
tmsize_t tiff_write(thandle_t,void*,tmsize_t){return 0;}
toff_t tiff_seek(thandle_t handle,toff_t offset,int origin){auto& memory=*static_cast<TiffMemory*>(handle);toff_t next=offset;if(origin==SEEK_CUR)next=memory.offset+offset;else if(origin==SEEK_END)next=static_cast<toff_t>(memory.size)+offset;if(next>memory.size)return static_cast<toff_t>(-1);memory.offset=next;return next;}
int tiff_close(thandle_t){return 0;}
toff_t tiff_size(thandle_t handle){return static_cast<toff_t>(static_cast<TiffMemory*>(handle)->size);}
int tiff_map(thandle_t handle,void** base,toff_t* size){auto& memory=*static_cast<TiffMemory*>(handle);*base=const_cast<std::uint8_t*>(memory.data);*size=static_cast<toff_t>(memory.size);return 1;}
void tiff_unmap(thandle_t,void*,toff_t){}
ImageData decode_tiff(const std::vector<std::uint8_t>& bytes){TiffMemory memory{bytes.data(),bytes.size(),0};TIFF* file=TIFFClientOpen("memory","r",static_cast<thandle_t>(&memory),tiff_read,tiff_write,tiff_seek,tiff_close,tiff_size,tiff_map,tiff_unmap);if(!file)throw Error(ABZ_ERROR_CORRUPT_INPUT,"TIFF decoding failed");std::uint32_t width=0,height=0;if(TIFFGetField(file,TIFFTAG_IMAGEWIDTH,&width)!=1||TIFFGetField(file,TIFFTAG_IMAGELENGTH,&height)!=1||width==0||height==0){TIFFClose(file);throw Error(ABZ_ERROR_CORRUPT_INPUT,"TIFF dimensions are invalid");}std::vector<std::uint32_t> raster(static_cast<std::size_t>(width)*height);if(TIFFReadRGBAImageOriented(file,width,height,raster.data(),ORIENTATION_TOPLEFT,0)!=1){TIFFClose(file);throw Error(ABZ_ERROR_CORRUPT_INPUT,"TIFF pixels could not be decoded");}TIFFClose(file);ImageData image;image.mime_type="image/tiff";image.encoded=bytes;image.width=width;image.height=height;image.rgba.resize(raster.size()*4);for(std::size_t index=0;index<raster.size();++index){image.rgba[index*4]=TIFFGetR(raster[index]);image.rgba[index*4+1]=TIFFGetG(raster[index]);image.rgba[index*4+2]=TIFFGetB(raster[index]);image.rgba[index*4+3]=TIFFGetA(raster[index]);}return image;}
#endif
}
std::pair<std::uint32_t,std::uint32_t> jpeg_dimensions(const std::vector<std::uint8_t>& b){if(b.size()<4||b[0]!=0xff||b[1]!=0xd8)throw Error(ABZ_ERROR_CORRUPT_INPUT,"Invalid JPEG signature");for(std::size_t p=2;p+9<b.size();){if(b[p++]!=0xff)continue;while(p<b.size()&&b[p]==0xff)++p;if(p>=b.size())break;const auto marker=b[p++];if(marker==0xd8||marker==0xd9)continue;if(p+2>b.size())break;const auto n=(b[p]<<8)|b[p+1];if(n<2||p+n>b.size())break;if((marker>=0xc0&&marker<=0xc3)||(marker>=0xc5&&marker<=0xc7)||(marker>=0xc9&&marker<=0xcb)||(marker>=0xcd&&marker<=0xcf)){return {std::uint32_t((b[p+5]<<8)|b[p+6]),std::uint32_t((b[p+3]<<8)|b[p+4])};}p+=n;}throw Error(ABZ_ERROR_CORRUPT_INPUT,"JPEG dimensions not found");}
ImageData decode(const std::vector<std::uint8_t>& b,const std::string& f){if(f=="png")return decode_png(b);if(f=="jpg"||f=="jpeg"||f=="bmp"||f=="gif")return decode_stb(b,f);
#ifdef ABZAR_HAS_WEBP
if(f=="webp")return decode_webp(b);
#endif
#ifdef ABZAR_HAS_TIFF
if(f=="tiff"||f=="tif")return decode_tiff(b);
#endif
throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,"This image decoder is not compiled in");}
std::vector<std::uint8_t> encode_png(const std::vector<std::uint8_t>& rgb,std::uint32_t w,std::uint32_t h,int level){if(rgb.size()!=std::size_t(w)*h*3)throw Error(ABZ_ERROR_INVALID_ARGUMENT,"RGB buffer size does not match image dimensions");std::vector<std::uint8_t> raw((std::size_t(w)*3+1)*h);for(std::uint32_t y=0;y<h;++y){raw[y*(w*3+1)]=0;std::memcpy(raw.data()+y*(w*3+1)+1,rgb.data()+std::size_t(y)*w*3,std::size_t(w)*3);}std::vector<std::uint8_t> packed(compressBound(raw.size()));uLongf packed_size=packed.size();if(compress2(packed.data(),&packed_size,raw.data(),raw.size(),std::clamp(level,0,9))!=Z_OK)throw Error(ABZ_ERROR_INTERNAL,"PNG compression failed");packed.resize(packed_size);std::vector<std::uint8_t> out={137,80,78,71,13,10,26,10};std::vector<std::uint8_t> ihdr;put32(ihdr,w);put32(ihdr,h);ihdr.insert(ihdr.end(),{8,2,0,0,0});chunk(out,"IHDR",ihdr);chunk(out,"IDAT",packed);chunk(out,"IEND",{});return out;}
std::vector<std::uint8_t> encode_jpeg(const std::vector<std::uint8_t>& rgb,std::uint32_t width,std::uint32_t height,int quality){if(rgb.size()!=static_cast<std::size_t>(width)*height*3)throw Error(ABZ_ERROR_INVALID_ARGUMENT,"RGB buffer size does not match JPEG dimensions");if(width>static_cast<std::uint32_t>(std::numeric_limits<int>::max())||height>static_cast<std::uint32_t>(std::numeric_limits<int>::max()))throw Error(ABZ_ERROR_OUT_OF_MEMORY,"JPEG dimensions are too large");std::vector<std::uint8_t> output;const auto result=stbi_write_jpg_to_func(write_callback,&output,static_cast<int>(width),static_cast<int>(height),3,rgb.data(),std::clamp(quality,1,100));if(result==0||output.size()<4)throw Error(ABZ_ERROR_INTERNAL,"JPEG encoding failed");return output;}
std::vector<std::uint8_t> encode_webp(const std::vector<std::uint8_t>& rgb,std::uint32_t width,std::uint32_t height,int quality){if(rgb.size()!=static_cast<std::size_t>(width)*height*3)throw Error(ABZ_ERROR_INVALID_ARGUMENT,"RGB buffer size does not match WebP dimensions");
#ifdef ABZAR_HAS_WEBP
std::uint8_t* encoded=nullptr;const auto size=WebPEncodeRGB(rgb.data(),static_cast<int>(width),static_cast<int>(height),static_cast<int>(width*3),static_cast<float>(std::clamp(quality,1,100)),&encoded);if(size==0||!encoded)throw Error(ABZ_ERROR_INTERNAL,"WebP encoding failed");std::vector<std::uint8_t> output(encoded,encoded+size);WebPFree(encoded);return output;
#else
(void)quality;throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,"WebP encoder is not compiled into this build");
#endif
}
}  // namespace abzar::images
