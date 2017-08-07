# ShaDai

iOS/AVFoundation project compilation

## How to Build

Load the project (“ShaDai.xcodeproj” file) using Xcode IDE

## Notable Projects

When you build and run the application, you will find main app screen providing several navigation menu options.

![Main Screen](/doc/images/main.png)

Among these, there will be explanations on README.md for notable projects.
The list of notable projects are as follows.

* Profile One
* Dual
* Editor

(By the way, sorry for poor naming)

## Profile One

The application capable of adding an animation which depicts flying ball’s path to a golf swing motion video

Influenced by [Shot Tracer](https://itunes.apple.com/us/app/shot-tracer/id1140451547?mt=8) application

![Profile One](/doc/images/profileOne.png)

Profile One has limited capability compared to the original application.
It is capable of

* Loading the file to add animation\*
* Modifying shape of the trajectory
* Configuring starting frame of the animation

You can choose the file to work on using the uppermost text field.
For further processing, you press “load” button. The button can only be pressed once.

You can modify the shape by dragging trajectory points (circles) on the video.

* Orange circle marks the starting point of path animation.
* Blue circle marks the finishing point of path animation.
* Purple circle marks the third point to determine the shape of path animation so that the path looks like a parabola that passes through three points.

You can check the video frames by moving the lowermost slider.
When buttons on each side of the slider are pressed, the video goes by one frame forwards/backwards.

Finally, you can press “save” button to export the video with animation. The frame of the video you are looking at when you press the button will be the starting position for the animation. 

![Profile One](/doc/images/p1vid1.png)

![Profile One](/doc/images/p1vid2.png)

## Dual

The application which plays two golf swing motion videos synchronously

![Dual](/doc/images/dual.png)

Dual application breaks down the swing motion into several steps and plays each synchronously.
To achieve this, for each step, the video which has a shorter play time for the step suspends until the other finishes the step. 
By doing so, both videos start each step at the same time.

Bottommost slider bar can be referred to as “master” slider, which tracks the entire video play and can be dragged.
On the meantime, each video’s actual play time is reflected on the gray-colored bar under the video. 
You can see the actual play for each video occasionally stops to synchronize with the other.

Unfortunately, the length (or time period) for each motion has to be configured manually.
When you load the video for the first time, you will be instructed to configure the video first.

![Dual](/doc/images/dualPreconfig.png)

You can press “Config” button to configure each motion’s starting point manually.
You can move slider along and press “Add” button to mark position as respective motion’s starting point.
 
![Dual](/doc/images/dualConfig.png)

There are four(4) disjoint steps in a swing motion, which are address, backswing, impact, and finish.
From upper segment controls, you can choose which motion point you are marking.

## Editor

The application capable of recording narration, supplementary drawings, playback status, etc.

![Editor](/doc/images/editor.png)

Upper part is related to drawing shapes.
You can use controls to choose the shape. The shape is added as you press the control button.
You can pick the shape on the screen by clicking on it. Picked shape has resizing controls (white circles) on it.
You can press “color” button to change the color of currently picked shape and all shapes you draw after.
You can press “delete” button to remove currently picked shape.
You can drag the picked shape to move it around and to resize it.

Bottom part is comprised of playback related controls and recording related controls.
For the former, there is a slider to seek through the video, segmented control to choose the play speed, and the “play/pause” button to toggle video play status.

For the latter, there are three buttons on the bottommost part of the screen.
The “start/finish” button starts/finishes recording session.
The “playback” button plays last recording session; i.e. narration, drawing shapes, playback/seek status during the record session are replayed.

![Editor](/doc/images/editorPB.png)

When the “save” button is pressed, all manipulations during the record session are rendered and exported to camera roll.

![Editor](/doc/images/editorSave.png)

Note that the “playback” button and “save” button are not enabled for the first time because you don’t have a record session yet. 
Once you record a session using the “start/finish” button for the first time, they are enabled, as shown below.

![Editor](/doc/images/editorPlayable.png)

## Implementation: Profile One

Profile One’s main features are: loading and seeking video, drawing and positioning a trajectory parabola, and exporting with animation.

### Loading and Seeking

Most of these features are simple thanks to powerful [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer) and [AVPlayerItem](https://developer.apple.com/documentation/avfoundation/avplayeritem) APIs. These are easy tasks, so I won’t cover their details.

### Drawing and Positioning a Trajectory Parabola

Three points on the video are represented as srcView, dstView, and vertexView objects (Yes. The third point was supposed to be a “vertex” of a trajectory. However, it was not possible.) and procuring their coordinates is rather a straightforward task. 

To draw a parabola (i.e. a quadratic curve), I used [UIBezierPath](https://developer.apple.com/documentation/uikit/uibezierpath), especially [addQuadCurve(to:controlPoint:)](https://developer.apple.com/documentation/uikit/uibezierpath/1624351-addquadcurve) method. For this, a simple simultaneous equation is solved to get a control path.

![Equation](/doc/images/equation/01.gif)

![Equation](/doc/images/equation/02.gif)

![Equation](/doc/images/equation/03.gif)

![Equation](/doc/images/equation/04.gif)

Solving equation involves matrix multiplication and, therefore, GLKit is used.
Getting the [control point for a quadratic bezier curve](https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Constructing_B.C3.A9zier_curves) is trivial, as follows.

![Equation](/doc/images/equation/05.gif)

![Equation](/doc/images/equation/06.gif)

In the meantime, the calculated curve is not drawn as-is, or as a sublayer to the view. Rather, it is drawn as a “mask” of a sublayer which is filled with red color everywhere so that only the masked area (which is a drawn path curve) is visible to the user. These two layers are `Shape` and `Wrapper` instance variables of [ProfileOneViewController](https://github.com/lsylove/ShaDai/blob/master/ShaDai/ProfileOneViewController.swift) in the project.

![Profile One](/doc/images/p1exp1.png)

The reason behind such indirect expression is explained later.

### Exporting with Animation

This part was the trickiest and frustrated me very much. The process is (primarily) written in [processVideo() method of ProfileOneViewController](https://github.com/lsylove/ShaDai/blob/master/ShaDai/ProfileOneViewController.swift#L202). For the most part, the method deals with `shapeLayer` and `shapeWrapper` CALayer objects. The two layers have similar relationship to previous `Shape` and `Wrapper`; i.e. shapeWrapper has the red fill and shapeLayer has a perspective stroke which masks the wrapper.

![Profile One](/doc/images/p1exp2.png)

The reason for dividing the red fill and the perspective stroke is to apply the animation for a path as simple as possible. Under such structure, to apply animation, the implementation only has to manipulate the stroke of `shapeWrapper`. It doesn’t have to deal with the shape with much more complex stroke `shapeLayer` has.

![Profile One](/doc/images/p1exp3.png)

To actually draw an animation into exporting video, a simple [AVVideoCompositionCoreAnimationTool](https://developer.apple.com/documentation/avfoundation/avvideocompositioncoreanimationtool) is utilized along with [AVMutableVideoCompositionLayerInstruction](https://developer.apple.com/documentation/avfoundation/avmutablevideocompositionlayerinstruction) and [AVMutableVideoCompositionInstruction](https://developer.apple.com/documentation/avfoundation/avmutablevideocompositioninstruction). This part of an implementation is not found at the view controller; instead, the code is located at [AVAnimationComposer](https://github.com/lsylove/ShaDai/blob/master/ShaDai/AVAnimationComposer.swift) object.

```swift
let layerComposition = AVMutableVideoComposition()
layerComposition.renderSize = videoSize
layerComposition.frameDuration = CMTimeMake(1, 30)
layerComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayerPlaceholder, in: parentLayer)

let targetTrack = composition.tracks(withMediaType: AVMediaTypeVideo).first!
let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: targetTrack)

let instruction = AVMutableVideoCompositionInstruction()
instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration)
instruction.layerInstructions = [layerInstruction]
layerComposition.instructions = [instruction]
```

Afterwards, as with regular exports, [AVAssetReader](https://developer.apple.com/documentation/avfoundation/avassetreader), [AVAssetReaderVideoCompositionOutput](https://developer.apple.com/documentation/avfoundation/avassetreadervideocompositionoutput), [AVAssetWriter](https://developer.apple.com/documentation/avfoundation/avassetwriter), and [AVAssetWriterInput](https://developer.apple.com/documentation/avfoundation/avassetwriterinput) are used to export the video and finally, [PHPhotoLibrary.performChanges(_:completionHandler:)](https://developer.apple.com/documentation/photos/phphotolibrary/1620743-performchanges) for exporting to camera roll.

## Implementation: Dual

Dual has two view screen and two view controllers: [DualViewController](https://github.com/lsylove/ShaDai/blob/master/ShaDai/DualViewController.swift) and [SwingConfigViewController](https://github.com/lsylove/ShaDai/blob/master/ShaDai/SwingConfigViewController.swift), the former for synchronous play and the latter for position configuration.

Both view controllers, especially the latter, uses [BarIndicatorView](https://github.com/lsylove/ShaDai/blob/master/ShaDai/BarIndicatorView.swift) to display the time position of each motion. The view component checks before each segment, or bar indicator, that shows the position is inserted so that all bars are in proper order.

```swift
for indicator in indicators {
        if ((indicator.value > value) != (indicator.orderPrority > priority)
                && indicator.identifier != identifier) {
                return false
        }
}
```

SwingConfigViewController is not that complex other than that: it preserves/forwards state via delegates, it triggers event on user’s trying to add a new position mark (i.e. bar indicator), it has simple controls for seeking the video, and so on.

In the meantime, DualViewController would have been something similar in complexity; however, it is not. It is mostly covering data transfer (again, using delegates) and play/pause/tick/seek controls but it also has to deal with manipulating AVPlayers regarding when to play/stop each video. 

To synchronize playing of each motion, [TimemarkParams](https://github.com/lsylove/ShaDai/blob/master/ShaDai/TimemarkParams.swift) object performs a series of calculation to translate the “master time” into actual play time for each video and vice versa.

TimemarkParams have four instance variables `mark`, `sub`, `offset`, and `timemarks` and they are initialized upon object construction.

\* Note that `markA` and `markB` are arguments storing each motion’s timing information.

```swift
self.mark = [ a: markA, b: markB ]
        
var dif = 0.0
let diffA = markA.map { a -> Double in defer { dif = a }; return a - dif }
        
dif = 0.0
let diffB = markB.map { a -> Double in defer { dif = a }; return a - dif }
        
let zipped = zip(diffA, diffB)
        
self.sub = zipped.map { $0 > $1 ? b : a }
let mins = zipped.map { min($0, $1) }
let diff = zipped.map { abs($0 - $1) }
        
var _offset = [T:[Double]]()
        
var sum = 0.0
_offset[a] = zip(sub, diff).flatMap { [0.0, $0 == a ? -$1 : 0.0] }.map { (sum += $0, sum).1 }
        
sum = 0.0
_offset[b] = zip(sub, diff).flatMap { [0.0, $0 == b ? -$1 : 0.0] }.map { (sum += $0, sum).1 }
        
self.offset = _offset
        
sum = 0.0
self.timemarks = zip(mins, diff).flatMap { [$0, $1] }.map { (sum += $0, sum).1 }
```

These operations perform something similar to following explanation.

Suppose each motion for A video starts at 5, 10, 18, 20, 25 seconds position and that 6, 9, 15, 18, 25 seconds for B. Also, both video has a 25 seconds play duration.

Then, `markA = [5, 10, 18, 20, 25]` and `markB = [6, 9, 15, 18, 25]`.

It would look something similar to this.

![Dual](/doc/images/dexp1.png)

When you play the videos at the same time from the start, it would be like this.

![Dual](/doc/images/dexp2.png)

However, as per spec, each motion should start at the same time: to implement the feature, I set one of them (which has a shorter previous motion) waits until the same motion of the other video ends so that both videos start the next video simultaneously.

![Dual](/doc/images/dexp3.png)

`diff` local variable stores each motion’s length, or difference between each motion’s starting position. In this case:

```
diffA = [5, 5, 8, 2, 5]
diffB = [6, 3, 6, 3, 7]
```

`sub` instance variable stores which one between A and B has a shorter play length for each motion; i.e. the one with lower `diff` value. For this, each member in `diffA` and `diffB` are compared in parallel.

```
sub = [A, B, B, A, A]
```

`timemark` instance variable provides key information regarding the “master” play controls. It is created by weaving two arrays in a manner that all “stopping time” information is kept.

![Dual](/doc/images/dexp4.png)

The final array is constructed by cumulating each segment’s value.

```
timemark = [5, 6, 9, 11, 17, 19, 21, 22, 27, 29]
```

First, the play length for master control becomes 29 seconds, which is the last element of the array.

In addition, combined with `sub`, it has information for A and B videos about when they play and stop during the master playing session. Like this:

![Dual](/doc/images/dexp5.png)

`timemark` instance variable has all information needed to play the videos synchronously. In the meantime, `offset` instance variable is used to figure out each video’s modified position when the master control’s slider is dragged.

In our case, “master” has 29 seconds of playing time. Video A stops from 5 seconds to 6 seconds of “master”, from 21 seconds to 22 seconds, and so on. The same for video B. Then, the correlation from master’s play time position to each video’s actual play time position should have a relationship like this.

![Dual](/doc/images/dexp6.png)

The implementation in TimemarkParams class gets `offset` value in a step similar to this.

1. Prepend zero to each element, using input array values.

```
preA = [0, 5, 0, 10, 0, 18, 0, 20, 0, 25]
preB = [0, 6, 0, 9, 0, 15, 0, 18, 0, 25]
```

2. If the video is `sub` between the two (similar to `timemark` array usage, 1/2 index is used to check which video is `sub`), subtract the value on the `timemark` array with the same position. If not, just replace the value with zero.

```
_preA = [0, -1, 0, 0, 0, 0, 0, -2, 0, -4]
_preB = [0, 0, 0, -2, 0, -4, 0, 0, 0, 0]
```

3. Replace all zeros to “previous element’s value”; except for the first element which keeps the value of zero.

```
offsetA = [0, -1, -1, -1, -1, -1, -1, -2, -2, -4]
offsetB = [0, 0, 0, -2, -2, -4, -4, -4, -4, -4]
```

When the offset is directly applied for each `timemark` segment positions, it looks like this.

![Dual](/doc/images/dexp7.png)

Therefore, the only exception is “when the video is paused”, and such case can be handled easily using `sub` and other arrays.
