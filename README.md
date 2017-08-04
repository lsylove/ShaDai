# ShaDai

iOS/AVFoundation project compilation

----------------------------------------------

## How to Build

Load the project (“ShaDai.xcodeproj” file) using Xcode IDE

----------------------------------------------

## Notable Projects

When you build and run the application, you will find main app screen providing several navigation menu options.

![Main Screen](/doc/images/main.png)

Among these, there will be explanations on README.md for notable projects.
The list of notable projects are as follows.

* Profile One
* Dual
* Editor

(By the way, sorry for poor naming)

----------------------------------------------

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

----------------------------------------------

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

----------------------------------------------

## Editor

The application capable of recording narration, supplementary drawings, playback status, etc.

![Editor](/doc/images/editor.png)

Upper part is related to drawing shapes.
You can use controls to choose the shape. The shape is added as you press the control button.
You can ‘pick’ the shape on the screen by clicking on it. Picked shape has resizing controls (white circles) on it.
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

----------------------------------------------
