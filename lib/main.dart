import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;


void main() => runApp(new AnimationApp());

class AnimationApp extends StatefulWidget {
  _AnimationAppState createState() => _AnimationAppState();
}

class _AnimationAppState extends State<AnimationApp> with SingleTickerProviderStateMixin {
  ui.Image image1;
  ui.Image image2;
  bool ready = false;

  AnimationController controller;
  Animation<double> animation;

  @override
  void dispose(){
    //clean up
    controller.dispose();
    image1.dispose();
    image2.dispose();
    //call super
    super.dispose();
  }

  @override
  void initState(){
    //create our animation
    controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    animation = Tween(begin: 0.0, end: 1.0).animate(controller);
    //allow super.initState to complete first
    super.initState();
    //load dependencies
    _loadAssets();
  }

  void _loadAssets() async {
    //load images and convert to format required by canvas to draw
    image1 = await _loadAssetAsImage( "images/image1.png" );
    image2 = await _loadAssetAsImage( "images/image2.png" );
    //update state to say we're ready
    setState((){
      ready = true;
    });
  }

  Future<ui.Image> _loadAssetAsImage( String key ) async {
    var data = await rootBundle.load( key );
    var codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    var frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
      appBar: new AppBar(
        title: new Text("Demo"),
      ),
      body:Stack(
       children: [
         Positioned(
           top: 0,
           left: 0,
           right: 0,
           bottom: 0,
           child: ready ? ImageEffectAnimation( animation:animation, image1:image1, image2:image2 ) : Container()
         )
       ]
      ),
      floatingActionButton: IconButton(icon:Icon(Icons.play_arrow), onPressed: (){
        controller.reset();
        controller.forward();
      },),
    ));
  }
}

class ImageEffectAnimation extends AnimatedWidget{
  
  ImageEffectAnimation({Key key, Animation<double> animation, this.image1, this.image2})
      : super(key: key, listenable: animation);

  final ui.Image image1;
  final ui.Image image2;

  Widget build(BuildContext context) {
    //build is called whenever the animation updates
    final Animation<double> animation = listenable;
    //repaint the 2 images using the animation to control the mix between them
    return CustomPaint(painter: ImageEffectPainter( image1:image1, image2:image2, mix:animation.value ));
  }

}

class ImageEffectPainter extends CustomPainter{
  ImageEffectPainter({@required this.image1, @required this.image2, this.mix});
  final ui.Image image1;
  final ui.Image image2;
  final double mix;

  @override
  void paint(Canvas canvas, Size size) {
    
    //set up paint
    
    //MASK - opacity is a function of mix 
    Paint paintMask = Paint()
    ..color = Color.fromARGB( (mix * 255.0).toInt(), 255, 255, 255);

    //OVERLAY - BlendMode uses the previously drawn content as a mask
    Paint paintImage = Paint()
    ..blendMode = BlendMode.srcATop;

    //Paint paintClear = Paint()..blendMode = BlendMode.clear;
    //canvas.drawColor( Colors.red, BlendMode.clear);

    //HOW DO WE WANT TO SPLIT UP THE IMAGE
    int numStepsX = 10;
    int numStepsY = 10;
    double overlap = 0.2;
    
    //THESE CALCULATIONS ARE USED A LOT - CREATE ONCE TO MAKE NEATER
    double imageWidth = image1.width.toDouble();
    double imageHeight = image1.width.toDouble();
    double srcSizeX = imageWidth / numStepsX;
    double srcSizeY = imageHeight / numStepsY;
    double targetSizeX = size.width / numStepsX;
    double targetSizeY = size.width / numStepsY;

    if( mix < 1 ){
      //THIS IS THE IMAGE WE ARE COMING FROM
      canvas.drawImageRect(
        image1, 
        Rect.fromLTWH(0.0,0.0,imageWidth,imageHeight), 
        Rect.fromLTWH(0.0,0.0,size.width,size.width), 
        paintImage
      );

      return;
      //SAVE LAYER - CREATES A NEW LAYER FOR US TO DRAW IN ISOLATION FROM THE PREVIOUS DRAWING
      canvas.saveLayer(Rect.fromLTRB(0.0,0.0,size.width,size.width), Paint());

      //DRAW OUR MASK - THIS IS GOING TO USE A GRID OF CIRCLES TO REVEAL
      for( int x = 0; x < numStepsX; x++ ){
        for( int y = 0; y < numStepsY; y++ ){
          
          /*canvas.drawCircle(
            Offset((x+0.5)*targetSizeX,(y+0.5)*targetSizeY),
            mix * targetSizeX,
            paintMask
          );*/
          

          canvas.drawRect(
            Rect.fromLTWH(
              (x+0.5*(1 - mix))*targetSizeX,
              (y+0.5*(1 - mix))*targetSizeY,
              mix * targetSizeX,
              mix * targetSizeY),
            paintMask
          );

        }
      }

      canvas.drawImageRect(image2, Rect.fromLTRB(0.0,0.0,500.0,500.0), Rect.fromLTRB(0.0,0.0,size.width,size.width), paintImage);
    }else{
      //canvas.drawImageRect(image2, Rect.fromLTRB(0.0,0.0,500.0,500.0), Rect.fromLTRB(0.0,0.0,size.width,size.width), paintImage);
    }
    
    
    /*
    //draw the image over the top
    for( int x = 0; x < numStepsX; x++ ){
      for( int y = 0; y < numStepsY; y++ ){
        canvas.drawImageRect(image2, 
        Rect.fromLTWH(x*srcSizeX,y*srcSizeY,mix*srcSizeX,mix*srcSizeY), 
        Rect.fromLTWH(x*targetSizeX,y*targetSizeY,mix*targetSizeX,mix*targetSizeY), 
        paintImage);
      }
    }
    */
    
  }

  @override
  bool shouldRepaint(ImageEffectPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return oldDelegate.image1 != this.image1 || oldDelegate.image2 != this.image2 || oldDelegate.mix != this.mix;
  }
}

