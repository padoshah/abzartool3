import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../app/l10n/app_localizations.dart';
import '../../core/models/file_entry.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../core/services/storage_service.dart';
import '../../shared/widgets/feature_scaffold.dart';

class PdfObjectEditorScreen extends StatefulWidget {
  const PdfObjectEditorScreen({super.key});
  @override State<PdfObjectEditorScreen> createState()=>_PdfObjectEditorScreenState();
}
class _PdfObjectEditorScreenState extends State<PdfObjectEditorScreen>{
  final search=TextEditingController(),replacement=TextEditingController(),objectName=TextEditingController(),page=TextEditingController(text:'1'),x=TextEditingController(text:'36'),y=TextEditingController(text:'36'),width=TextEditingController(text:'180'),height=TextEditingController(text:'120');
  FileEntry? pdf,image;String? output;Object? error;bool running=false;
  Future<void> pickPdf()async{final files=await FileService().pickFiles(multiple:false);if(files.isNotEmpty)setState(()=>pdf=files.first);}
  Future<void> pickImage()async{final files=await FileService().pickFiles(multiple:false);if(files.isNotEmpty)setState(()=>image=files.first);}
  Future<String> outputPath()async{final root=await StorageService().temporaryJobs();return p.join(root.path,'${p.basenameWithoutExtension(pdf!.path)}-objects-edited.pdf');}
  Future<void> replaceText()async{if(pdf==null||search.text.isEmpty)return;setState((){running=true;error=null;});try{final result=await outputPath();final pageNumber=int.tryParse(page.text);await NativeOperations.replacePdfText(inputPath:pdf!.path,outputPath:result,search:search.text,replacement:replacement.text,pageIndex:pageNumber==null?-1:pageNumber-1);if(mounted)setState(()=>output=result);}catch(value){if(mounted)setState(()=>error=value);}finally{if(mounted)setState(()=>running=false);}}
  Future<void> deleteImage()async{if(pdf==null||objectName.text.isEmpty)return;setState((){running=true;error=null;});try{final result=await outputPath();await NativeOperations.deletePdfImage(inputPath:pdf!.path,outputPath:result,pageIndex:(int.tryParse(page.text)??1)-1,objectName:objectName.text);if(mounted)setState(()=>output=result);}catch(value){if(mounted)setState(()=>error=value);}finally{if(mounted)setState(()=>running=false);}}
  Future<void> addImage()async{if(pdf==null||image==null)return;setState((){running=true;error=null;});try{final result=await outputPath();await NativeOperations.addPdfImage(inputPath:pdf!.path,outputPath:result,pageIndex:(int.tryParse(page.text)??1)-1,imagePath:image!.path,imageFormat:image!.extension,x:double.tryParse(x.text)??36,y:double.tryParse(y.text)??36,width:double.tryParse(width.text)??180,height:double.tryParse(height.text)??120);if(mounted)setState(()=>output=result);}catch(value){if(mounted)setState(()=>error=value);}finally{if(mounted)setState(()=>running=false);}}
  Future<void> replaceImage()async{if(pdf==null||image==null)return;setState((){running=true;error=null;});try{final result=await outputPath();await NativeOperations.replacePdfImage(inputPath:pdf!.path,outputPath:result,pageIndex:(int.tryParse(page.text)??1)-1,objectName:objectName.text,replacementPath:image!.path,replacementFormat:image!.extension);if(mounted)setState(()=>output=result);}catch(value){if(mounted)setState(()=>error=value);}finally{if(mounted)setState(()=>running=false);}}
  @override void dispose(){for(final controller in <TextEditingController>[search,replacement,objectName,page,x,y,width,height])controller.dispose();super.dispose();}
  @override Widget build(BuildContext context){final l=AppLocalizations.of(context);return FeatureScaffold(title:l.pdfObjectEditor,child:ListView(padding:const EdgeInsets.all(20),children:<Widget>[
    FilledButton.icon(onPressed:running?null:pickPdf,icon:const Icon(Icons.picture_as_pdf),label:Text(l.selectFiles)),if(pdf!=null)ListTile(title:Text(pdf!.name)),
    const SizedBox(height:16),TextField(controller:page,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:l.pageIndex)),TextField(controller:search,decoration:InputDecoration(labelText:l.searchText)),TextField(controller:replacement,decoration:InputDecoration(labelText:l.replacementText)),const SizedBox(height:8),FilledButton.icon(onPressed:running?null:replaceText,icon:const Icon(Icons.find_replace),label:Text(l.replaceTextObject)),
    const Divider(height:32),TextField(controller:objectName,onChanged:(_)=>setState((){}),decoration:InputDecoration(labelText:l.objectName)),OutlinedButton.icon(onPressed:running?null:pickImage,icon:const Icon(Icons.image),label:Text(l.selectReplacementImage)),if(image!=null)ListTile(title:Text(image!.name)),Wrap(spacing:8,children:<Widget>[SizedBox(width:130,child:TextField(controller:x,decoration:InputDecoration(labelText:l.imageX))),SizedBox(width:130,child:TextField(controller:y,decoration:InputDecoration(labelText:l.imageY))),SizedBox(width:130,child:TextField(controller:width,decoration:InputDecoration(labelText:l.imageWidth))),SizedBox(width:130,child:TextField(controller:height,decoration:InputDecoration(labelText:l.imageHeight)))]),Row(children:<Widget>[Expanded(child:FilledButton.icon(onPressed:running?null:addImage,icon:const Icon(Icons.add_photo_alternate),label:Text(l.addImageObject))),const SizedBox(width:8),Expanded(child:FilledButton.icon(onPressed:running?null:replaceImage,icon:const Icon(Icons.image_search),label:Text(l.replaceImageObject)))]),OutlinedButton.icon(onPressed:running||objectName.text.isEmpty?null:deleteImage,icon:const Icon(Icons.delete),label:Text(l.deleteImageObject)),
    if(running)const LinearProgressIndicator(),if(error!=null)Text(error.toString(),style:TextStyle(color:Theme.of(context).colorScheme.error)),if(output!=null)ListTile(title:Text(l.completed),trailing:IconButton(tooltip:l.open,icon:const Icon(Icons.open_in_new),onPressed:()=>FileService().open(output!))),Text(l.sourceUnchanged,textAlign:TextAlign.center)
  ]));}
}
