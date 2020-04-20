import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart' as Constants;

class AppWidgets {
  static Widget createSimpleExpendedSizedBoxProgress() {
    return Stack(
      children: <Widget>[
        SizedBox.expand(
          child: Container(
            decoration: BoxDecoration(color: Constants.primaryColor30),
            child: Center(
                child: Wrap(children: <Widget>[CircularProgressIndicator()])),
          ),
        ),
      ],
    );
  }
}

class ClapFAB extends StatefulWidget {
  final countCircleColor;
  final countTextColor;
  final hasShadow;
  final shadowColor;
  final floatingOutlineColor;
  final floatingBgColor;
  final sparkleColor;
  final defaultIcon;
  final defaultIconColor;
  final filledIcon;
  final filledIconColor;
  final clapFabCallback;
  final defaultImage;
  final defaultImageColor;
  final filledImage;
  final filledImageColor;
  final clearCountOnUserUpTap;

  const ClapFAB.icon(
      {this.countCircleColor = Colors.blue,
      this.countTextColor = Colors.white,
      this.hasShadow = false,
      this.shadowColor = Colors.blue,
      this.floatingOutlineColor = Colors.white,
      this.floatingBgColor = Colors.white,
      this.defaultIcon = Icons.favorite_border,
      this.defaultIconColor = Colors.blue,
      this.sparkleColor = Colors.blue,
      this.filledIcon = Icons.favorite,
      this.filledIconColor = Colors.blue,
      this.clapFabCallback,
      this.clearCountOnUserUpTap = true})
      : defaultImage = null,
        defaultImageColor = null,
        filledImage = null,
        filledImageColor = null;

  @override
  _ClapFABState createState() => _ClapFABState();
}

enum ScoreWidgetStatus { HIDDEN, BECOMING_VISIBLE, VISIBLE, BECOMING_INVISIBLE }

class _ClapFABState extends State<ClapFAB> with TickerProviderStateMixin {
  int counter = 0;
  double _sparklesAngle = 0.0;
  ScoreWidgetStatus _scoreWidgetStatus = ScoreWidgetStatus.HIDDEN;
  final duration = Duration(milliseconds: 400);
  final oneSecond = Duration(seconds: 1);
  Random random;
  Timer holdTimer, scoreOutETA;
  AnimationController scoreInAnimationController,
      scoreOutAnimationController,
      scoreSizeAnimationController,
      sparklesAnimationController;
  Animation scoreOutPositionAnimation, sparklesAnimation;

  initState() {
    super.initState();
    random = Random();
    scoreInAnimationController =
        AnimationController(duration: Duration(milliseconds: 150), vsync: this);
    scoreInAnimationController.addListener(() {
      setState(() {}); // Calls render function
    });

    scoreOutAnimationController =
        AnimationController(vsync: this, duration: duration);
    scoreOutPositionAnimation = Tween(begin: 100.0, end: 150.0).animate(
        CurvedAnimation(
            parent: scoreOutAnimationController, curve: Curves.easeOut));
    scoreOutPositionAnimation.addListener(() {
      setState(() {});
    });
    scoreOutAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scoreWidgetStatus = ScoreWidgetStatus.HIDDEN;
        if (widget.clapFabCallback != null) {
          widget.clapFabCallback(counter);
        }
        if (widget.clearCountOnUserUpTap) {
          counter = 0;
        }
      }
    });

    scoreSizeAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 150));
    scoreSizeAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        scoreSizeAnimationController.reverse();
      }
    });
    scoreSizeAnimationController.addListener(() {
      setState(() {});
    });

    sparklesAnimationController =
        AnimationController(vsync: this, duration: duration);
    sparklesAnimation = CurvedAnimation(
        parent: sparklesAnimationController, curve: Curves.easeIn);
    sparklesAnimation.addListener(() {
      setState(() {});
    });
  }

  dispose() {
    scoreInAnimationController.dispose();
    scoreOutAnimationController.dispose();
    super.dispose();
  }

  void increment(Timer t) {
    scoreSizeAnimationController.forward(from: 0.0);
    sparklesAnimationController.forward(from: 0.0);
    setState(() {
      counter++;
      _sparklesAngle = random.nextDouble() * (2 * pi);
    });
  }

  void onTapDown(TapDownDetails tap) {
    // User pressed the button. This can be a tap or a hold.
    if (scoreOutETA != null) {
      scoreOutETA.cancel(); // We do not want the score to vanish!
    }
    if (_scoreWidgetStatus == ScoreWidgetStatus.BECOMING_INVISIBLE) {
      // We tapped down while the widget was flying up. Need to cancel that animation.
      scoreOutAnimationController.stop(canceled: true);
      _scoreWidgetStatus = ScoreWidgetStatus.VISIBLE;
    } else if (_scoreWidgetStatus == ScoreWidgetStatus.HIDDEN) {
      _scoreWidgetStatus = ScoreWidgetStatus.BECOMING_VISIBLE;
      scoreInAnimationController.forward(from: 0.0);
    }
    increment(null); // Take care of tap
    holdTimer = Timer.periodic(duration, increment); // Takes care of hold
  }

  void onTapUp(TapUpDetails tap) {
    // User removed his finger from button.
    scoreOutETA = Timer(oneSecond, () {
      scoreOutAnimationController.forward(from: 0.0);
      _scoreWidgetStatus = ScoreWidgetStatus.BECOMING_INVISIBLE;
    });
    holdTimer.cancel();
  }

  Widget getClapButton() {
    // Using custom gesture detector because we want to keep increasing the claps
    // when user holds the button.

    var extraSize = 0.0;
    if (_scoreWidgetStatus == ScoreWidgetStatus.VISIBLE ||
        _scoreWidgetStatus == ScoreWidgetStatus.BECOMING_VISIBLE) {
      extraSize = scoreSizeAnimationController.value * 3;
    }
    return GestureDetector(
        onTapUp: onTapUp,
        onTapDown: onTapDown,
        child: Container(
          height: 60.0 + extraSize,
          width: 60.0 + extraSize,
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
              border:
                  Border.all(color: widget.floatingOutlineColor, width: 1.0),
              borderRadius: BorderRadius.circular(50.0),
              color: widget.floatingBgColor,
              boxShadow: [
                widget.hasShadow
                    ? BoxShadow(color: widget.shadowColor, blurRadius: 8.0)
                    : BoxShadow()
              ]),
          child: widget.defaultImage == null
              ? Icon(
                  counter > 0 ? widget.filledIcon : widget.defaultIcon,
                  color: counter > 0
                      ? widget.filledIconColor
                      : widget.defaultIconColor,
                  size: 30.0,
                )
              : ImageIcon(
                  new AssetImage(
                      counter > 0 ? widget.filledImage : widget.defaultImage),
                  color: counter > 0
                      ? widget.filledImageColor
                      : widget.defaultImageColor,
                  size: 30.0),
        ));
  }

  Widget getScoreButton() {
    var scorePosition = 0.0;
    var scoreOpacity = 0.0;
    var extraSize = 0.0;
    switch (_scoreWidgetStatus) {
      case ScoreWidgetStatus.HIDDEN:
        break;
      case ScoreWidgetStatus.BECOMING_VISIBLE:
      case ScoreWidgetStatus.VISIBLE:
        scorePosition = scoreInAnimationController.value * 100;
        scoreOpacity = scoreInAnimationController.value;
        extraSize = scoreSizeAnimationController.value * 3;
        break;
      case ScoreWidgetStatus.BECOMING_INVISIBLE:
        scorePosition = scoreOutPositionAnimation.value;
        scoreOpacity = 1.0 - scoreOutAnimationController.value;
    }

    var stackChildren = <Widget>[];

    var firstAngle = _sparklesAngle;
    var sparkleRadius = (sparklesAnimationController.value * 50);
    var sparklesOpacity = (1 - sparklesAnimation.value);

    for (int i = 0; i < 5; ++i) {
      var currentAngle = (firstAngle + ((2 * pi) / 5) * (i));
      var sparklesWidget = Positioned(
        child: Transform.rotate(
            angle: currentAngle - pi / 2,
            child: Opacity(
                opacity: sparklesOpacity,
                child: Image.asset(
                  "assets/sparkles.png",
                  color: widget.sparkleColor,
                  width: 14.0,
                  height: 14.0,
                ))),
        left: (sparkleRadius * cos(currentAngle)) + 20,
        top: (sparkleRadius * sin(currentAngle)) + 20,
      );
      stackChildren.add(sparklesWidget);
    }

    stackChildren.add(Opacity(
        opacity: scoreOpacity,
        child: Container(
            height: 50.0 + extraSize,
            width: 50.0 + extraSize,
            decoration: ShapeDecoration(
              shape: CircleBorder(side: BorderSide.none),
              color: widget.countCircleColor,
            ),
            child: Center(
                child: Text(
              "+" + counter.toString(),
              style: TextStyle(
                  color: widget.countTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.0),
            )))));

    var _currentWidget = Positioned(
        child: Stack(
          alignment: FractionalOffset.center,
          overflow: Overflow.visible,
          children: stackChildren,
        ),
        bottom: scorePosition);
    return _currentWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Stack(
        alignment: FractionalOffset.center,
        overflow: Overflow.visible,
        children: <Widget>[
          getScoreButton(),
          getClapButton(),
        ],
      ),
    );
  }
}
