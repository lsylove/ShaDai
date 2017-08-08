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

## Implementation: Editor

Compared to all the other projects in the compilation, Editor project is very large. It uses complicated class relationship hierarchy shown below.

![Editor](/doc/images/exp1.png)

* [EditorViewController](https://github.com/lsylove/ShaDai/blob/master/ShaDai/EditorViewController.swift): View controller responsible for main scene, whose responsibilities include handling various control responses, forwarding data to and receiving data as delegate from ColorPickerViewController, managing record sessions, etc.

* [PlayerView](https://github.com/lsylove/ShaDai/blob/master/ShaDai/PlayerView.swift): Implemented using AVPlayer and AVPlayerLayer, the class has been used throughout the project, making nothing so special about it.

* [ShapeView](https://github.com/lsylove/ShaDai/blob/master/ShaDai/ShapeView.swift): View object representing each shape. It has basic shape information like appearance, size, and color. Also, it handles panning (dragging) events and resulting resize/translate by itself. Because of such responsibility, it also stores data for its own boundary and its position within it.

* [RecordSession](https://github.com/lsylove/ShaDai/blob/master/ShaDai/RecordSession.swift): RecordSession is deployed to record each event during the recording period and to replay recorded data during playback/export.

* [EventEntity](https://github.com/lsylove/ShaDai/blob/master/ShaDai/EventEntity.swift) and its implementations: Each EventEntity object abstracts the “event” that occurred during the recording session and the session is made up of a pair of (the time event occurred, the event) values.

* [RecordExportSession](https://github.com/lsylove/ShaDai/blob/master/ShaDai/RecordExportSession.swift): RecordExportSession is used by RecordSession when exporting. It mainly configures exporting related assets (aforementioned AVAssetReader, AVAssetWriter, ...) and format descriptors.

* [ImageRenderer](https://github.com/lsylove/ShaDai/blob/master/ShaDai/ImageRenderer.swift): Located within RecordExportSession, ImageRenderer captures each scene after the event and renders them into pixel buffers that are appended by RecordExportSession.

* [ColorPickerViewController](https://github.com/lsylove/ShaDai/blob/master/ShaDai/ColorPickerViewController.swift): The view controller manages “color change” screen. It has nothing but transferring picked color information back to the delegate.

* [HSBColorPicker](https://github.com/lsylove/ShaDai/blob/master/ShaDai/HSBColorPicker.swift): Courtesy to [StackOverflow](https://stackoverflow.com/a/34142316), this functioning view element could be obtained very easily. Fixed minor gesture glitches.

### AVPlayer

Nearly all projects cover usage with AVPlayer so, again, it is redundant to describe how PlayerView and associated controls are implemented.

### Drawing and Editing Shapes

Shapes are implemented as ShapeView in this project. 

Shapes deal with dragging events for resizing and translation on its own. These events are received via three sublayers: aView, bView, and dView. The former two marks the two edge points (“circles”) of the shape and, when dragged, resizes the shape. The latter is invisible and moves the shape when dragged.

![Editor](/doc/images/exp2.png)

ShapeView has `isSelected` calculated property. When this property goes off, all of sublayers become hidden so that they don’t receive any panning events. In addition, circles which displays resizing point also disappear (due to being hidden), making visual difference to the user.

From the user’s perspective, only one shape can be selected at the time. The user can select the shape by clicking (tapping) on it. When no shape is on the space where the user tapped, no shape becomes selected (all shapes are deselected). If there is one, that shape is the one selected. If there are more than one, the most recently drawn shape gets priority.

However, if such point is clicked more than once or, more generally, one of stacked shapes is previously selected by the user, the next shape will be the one created before the previous selection. This policy is set to prevent some older shapes from not being able to be selected.

![Editor](/doc/images/exp3.png)

Such functionality is implemented in [EditorViewController.pickShape(recognizer:)](https://github.com/lsylove/ShaDai/blob/master/ShaDai/EditorViewController.swift#L505). It uses `checkup` local variable to make sure newly selected shape is older than previously selected shape.

More specifically, no shape can be chosen while `checkup` is false (see 524th line). When the selected shape is found, `checkup` is turned to true, enabling the following shapes to be chosen. Since the elements are iterated in reverse order (to give chance to newer ones in general situations), after “checked up”, only older ones are eligible for checking.

Check this example regarding the point with <2> and <3> only. In this case, <3> is the previously selected shape before tapping.

![Editor](/doc/images/exp4.png)

However, if the checked up element is the last eligible element, or the oldest, in the iteration, there is chance some other elements are eligible to be chosen yet neglected
because of not being checked up yet. To overcome such issue, in the absence of chosen shape, the array is iterated once more to choose the proper one.

Check this example with the same point tapped, but different shape (<2>) is chosen at the time of tapping.

![Editor](/doc/images/exp5.png)

The function also handles other situations like when no shape is eligible, no shape is currently picked, tapped area does not contain currently picked shape, etc. You can check the code.

In the meantime, when the user changes color using HSBColorPicker, currently picked shape also changes color. This is trivial. One shortcoming is that the user cannot change multiple shapes’ color at the same time this way (or, in fact, in any other way).

### Recording and Playback

Recording is implemented with RecordSession. RecordSession records the state using events; for example, whenever the user changes the playing speed, it is recorded. The same thing happens when the user drags the slider to change play position, presses controls to put a new shape, drags the shape to resize, and so forth. 

To record events real-time, EditorViewController calls [RecordSession.record(entity:)](https://github.com/lsylove/ShaDai/blob/master/ShaDai/RecordSession.swift#L73) everywhere from control event handlers to delegate responses to record start/finish points. One notable feature is ShapeView’s [ShapeViewGestureRecognitionDelegate](https://github.com/lsylove/ShaDai/blob/master/ShaDai/ShapeView.swift#L11). While most of view state changes are handled in EditorViewController, shape resize/panning is handled in ShapeView so that RecordSession cannot record such changes (ShapeView and RecordSession has no relation; see class diagram above). ShapeViewGestureRecognitionDelegate is, although clunky, added to ShapeView to send response to the delegate (in this case, EditorViewController) so that shape change events could be recorded, too.

All these events are recorded and kept with time information: when each event occurred. Time information has a unit of “ticks” (rather than real time) to ease the calculation. To save events, [EventEntity](https://github.com/lsylove/ShaDai/blob/master/ShaDai/EventEntity.swift) and its subclass implementations are used depending on nature of the event; for instance, [FrameEvent](https://github.com/lsylove/ShaDai/blob/master/ShaDai/EventEntity.swift#L57) for frame change, [ShapeRelatedEvent](https://github.com/lsylove/ShaDai/blob/master/ShaDai/EventEntity.swift#L154) for shape change, and so on. RecordSession’s `events` dictionary achieves “heterogeneous container polymorphism”.

For playback on UI scene, RecordSession calculates back play time period between each events (it converts tick time back into real time differences) and executes each event back in sequence. Managing execution with time period is implemented using [DispatchQueue.asyncAfter(deadline:execute:)](https://developer.apple.com/documentation/dispatch/dispatchqueue/2300020-asyncafter) and a [DispatchSemaphore](https://developer.apple.com/documentation/dispatch/dispatchsemaphore) object (named `executionBarrier` since it does something similar to a barrier).

```swift
let keysSorted = self.events.keys.sorted()
let seq = zip(keysSorted, keysSorted.dropFirst())
            
for (curr, next) in seq {
        let diff = Double(next - curr)
        executionBarrier.wait()
                
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(diff * 1000.0 / self.frequency))) {
                executionBarrier.signal()
                for entity in self.events[next]! {
                        entity.execute(player: playerView.player!, superView: superView, metadata: &self.metadata)
                }
        }
}
DispatchQueue.main.async {
        completionHandler?()
}
```

Playback is mostly straightforward. However, one issue made playback much more complicated than it should. It is mainly due to how shapes are handled.

In my implementation, for playback and exporting, existing ShapeView objects are reused rather than recreated. This makes everything complex because, comparing before and after recording session, there are shapes deleted during the session and those created during the session. Some shapes are even created and deleted during the session!

Consider the following example.

![Editor](/doc/images/exp6.png)

During the recording, shapes change position, are added, and/or are removed from the screen. Each shape-related event (ShapeRelatedEvent and PanningEvent) has an associated shape. The sequence of events (in respect to time windows) and the relationship between objects are implemented this way.

![Editor](/doc/images/exp7.png)

Meanwhile, EditorViewController itself tracks currently visible ShapeViews to determine which shape to “select” when user presses the screen. Note that EditorViewController only has a list of shapes on the scene. In our scenario, it should look like this.

![Editor](/doc/images/exp8.png)

The implementation reuses ShapeView objects. To achieve this, EventEntity objects as well as EditorViewController have a strong reference to associated ShapeView object. Without continued reference, the view controller could not restore, for example, ShapeView <2> and ShapeView <4> because they are removed from the view controller. In short, all shapes that appeared during recording has their reference kept by EventEntity objects.

![Editor](/doc/images/exp9.png)

It should be noted that EventEntity objects do not have information regarding “initial” position of each ShapeView object. For example, in this recording session, it is only known for ShapeView <1> that it moved to right side and it became larger. It is never saved on these events that the shape was on the upper left corner. This can lead to confusion because ShapeView objects are reused. When the shape is on the center, video playback will result in the shape being moved further right and becoming even larger.

![Editor](/doc/images/exp7.png)

Only PanningEvent is saved, not initial location and such.

This implies that proper state save and restore functionality is required. For this, EditorViewController keeps record for state of all shapes at the time of record start so that these shapes are set to previous state at the start of playback. This container keeps the reference of each shape at the time and its position, size, and other state information as a key-value. This object is named `previous` instance variable.

![Editor](/doc/images/exp10.png)

At the start of playback, all visible objects are initialized to state when the recording started. Such initialization is done using the information in `previous` container. Starting from initialized state, the playback can be performed exactly the same as the time when the recording took place.

However, there are more issues to consider. The user might have drawn more shapes, removed some of them, etc. after recording is finished. It is definitely possible for a user to edit shape between the end of recording session and the playback. Therefore, there are actually three, not two, states information to consider.

![Editor](/doc/images/exp11.png)

Therefore, not only that the shapes should return to previous state at the beginning of playback, but also that the shapes should return to the state at the time of pressing the “playback” button from the state at the end of playback. These state transitions can be divided into three.

![Editor](/doc/images/exp12.png)

EditorViewController is responsible for transition (1) and (3). The former is to position the shapes to the state at the beginning of playback and the latter is to position the shapes back to the state at the time of pressing the “playback” button. Transition (2) is automatically performed through EventEntity execution.

The procedure can be summarized as follows.

![Editor](/doc/images/exp13.png)

* When “start/finish” button is pressed to start the recording session, all visible shapes’ data are saved to `self.previous`. (a, b, f, g)

* When “start/finish” button is pressed again to finish the recording session, all visible shapes’ references are saved to `self.inter`. (b, c, d, g) Unlike `self.previous`, `self.inter` does not have to save individual shape’s position and other data. The reason could be this.

	- for c, d: They didn’t exist at the time of recording start: They are created during the session. When entering the view, all ShapeView object are initialized at the same position.

	- for b, g: They existed at the time of recording start. Data in `self.previous` is sufficient to initialize their position for playback.

* When “playback” is pressed, initialization takes place before the actual playback. However, before initialization, current shape information should be saved for transition (3). The data is saved in `futureSnapshot` local variable in playback() method. The snapshot has a copy of all (d, e, f, g) shapes at the time of playback.\*

\*: Not “all” of them is necessary, for example, for “e” hiding might be sufficient. Maybe simplicity was key concern at the time of implementation.

```swift
var futureSnapshot: [ShapeView: ShapeView] = [:]
zip(shapes, shapes.map{ $0.copy() as! ShapeView }).forEach { futureSnapshot[$0.0] = $0.1 }
```

* Transition (1): First, hide all of currently visible shapes (d, e, f, g) and initialize shapes’ state with `self.previous`. Previous shapes (a, b, f, g) are also marked visible.

```swift
for shape in shapes {
        returnShapeToOriginalPosition(shape)
        shape.removeFromSuperview()
}
for (curr, prev) in previous {
        curr.absA = prev.absA
        curr.absB = prev.absB
        curr.c = prev.c
                    
        if (prev.isSelected) {
                curr.isSelected = true
        } else {
                curr.isSelected = false
        }
                    
        playerView.addSubview(curr)
        curr.setNeedsDisplay()
}
```

* Start executing RecordSession [Transition (2)].

* Transition (3): Hide and set to initial position all of shapes in `self.inter` (b, c, d, g) and restore shapes in `futureSnapshot` (d, e, f, g).

```swift
for shape in self.inter {
        returnShapeToOriginalPosition(shape)
        shape.removeFromSuperview()
}
for (curr, future) in futureSnapshot {
        curr.absA = future.absA
        curr.absB = future.absB
        curr.c = future.c
                    
        if (future.isSelected) {
                curr.isSelected = true
        }
                    
        self.playerView.addSubview(curr)
        curr.setNeedsDisplay()
}
```

### Exporting

This part is full of complicated API usage and weird async/DispatchSemaphore usages. 

For exporting, every logic deployed in [Recording and Playback](https://github.com/lsylove/ShaDai#recording-and-playback) are applied the same way except that exporting-related operations are added. It is the only entry point to RecordExportSession and ImageRender objects.

This code snippet explains [RecordSession.exportAsFile(playerView:view:fileURL:completionHandler:)](https://github.com/lsylove/ShaDai/blob/master/ShaDai/RecordSession.swift#L107) method’s functionality.

```swift

                ...

                // sequentialConsumer acts as a single worker thread. (a DispatchQueue object)
                sequentialConsumer.async {

                        // progressCount for reporting progress to delegate (EditorViewController which displays progress in a bar)
                        var progressCount = 0
            
                        for ticks in keysSorted {
                
                                // WAITS until rendering of previous frame is complete!
                                self.rendererBarrier.wait()
                
                                // report progress
                                let progress = Double(progressCount) / Double(self.events.count)
                                self.delegate?.reportProgress(reporter: self, progress: progress, count: self.events.count)
                
                                // increment progress (we are one step done! aren’t we?)
                                progressCount += 1
                
                                // execute events for the next frame in main thread
                                DispatchQueue.main.async {
                                        var targetType = self.events[ticks]!.first!.target
                    
                                        // execute all events for the next frame
                                        for entity in self.events[ticks]! {
                                                targetType = targetType != entity.target ? .any : targetType
                                                entity.execute(player: playerView.player!, superView: view, metadata: &self.metadata)
                                        }
                    
                                        let time = CMTime(seconds: Double(ticks) / self.frequency, preferredTimescale: 1000)
                    
                                        // render this updated frame to video being exported
                                        exportSession.append(view: view, playerView: playerView, targetType: targetType, time: time)
                                }
                        }
            
                        // WAITS once more (for the last frame’s VoidEvent entity)
                        self.rendererBarrier.wait()

                        // and then done. work on post-process
                        exportSession.markAsFinished(completionHandler: completionHandler)
                }
        }
}

extension RecordSession: RecordExportSessionDelegate {
    
        // PROGRESS onc rendering the frame is done (“appending” means it was appended to export queue)
        func appendingDone(session: RecordExportSession, buffer: CVPixelBuffer, time: CMTime, progress: Double) {
                rendererBarrier.signal()
        }
    
}
```

RecordExportSession uses standard AVAssetReader, AVAssetWriter and corresponding input/output objects to handle the task. There are several differences, though. First, it also deals with audio track. During recording, audio data is not compressed and follows linear PCM format. For export the format is compressed into MPEG-4 AAC.

Second, images that contained captured frames also make up part of the video. In fact, the resulting video does not have any “source” video and all visible elements are comprised of captured frames from the scene. To do so, an instance of [AVAssetWriterInputPixelBufferAdaptor](https://developer.apple.com/documentation/avfoundation/avassetwriterinputpixelbufferadaptor) is used to append image (of type [CVPixelBuffer](https://developer.apple.com/documentation/corevideo/cvpixelbuffer)) to AVAssetWriterInput.

Third, export session tries to maintain concurrency. UI update such as executing events and updating progress bars are exclusively done on UI thread. Capturing and rendering the image into CVPixelBuffer is done in a worker thread. Appending the captured image from export queue to AVAssetWriter is done in another thread. Writing audio asset data into the writer is done in yet another thread. [RecordExportSession.markAsFinished(completionHandler:)](https://github.com/lsylove/ShaDai/blob/master/ShaDai/RecordExportSession.swift#L283) is run in *another* worker thread and checks termination conditions for all those worker threads (excluding itself. meh)

Some note on ImageRenderer: Although the class offers various functions to render an image object into another object, the only (effectively) used method in the project is [render(shapeView:playerView:)](https://github.com/lsylove/ShaDai/blob/master/ShaDai/ImageRenderer.swift#L123) method. The method signature might look a bit weird in that it receives “optionals”. The reasoning behind can be inferred from the [calling point](https://github.com/lsylove/ShaDai/blob/master/ShaDai/RecordExportSession.swift#L266).

```swift
switch targetType {
case .any: buffer = self.renderer.render(shapeView: view, playerView: playerView)
case .shape: buffer = self.renderer.render(shapeView: view, playerView: nil)
case .player: buffer = self.renderer.render(shapeView: nil, playerView: playerView)
}
```

The reason it receives optionals is to encourage caching; when only the state regarding the shape is changed (e.g. new shape, shape resized, etc), only ShapeView superview layer is rendered again to update itself to newer frame. Similarly, when only the state regarding the video is changed (e.g. frame change), only PlayerView layer is rendered again. Either case, the other party who is not changed does not need to be rendered again. After each layer is rendered and ready as CVPixelBuffer, they are composited using CISourceOverCompositing filter (please see [CIImage.compositingOver(_:)](https://developer.apple.com/documentation/coreimage/ciimage/1437837-composited)).

![Editor](/doc/images/exp14.png)

Most of the other processes are simple and straightforward, provided that it heavily uses asynchronous operations to try to be efficient.

Similar to Profile One functionality, Editor exports the video to camera roll.
