/*
     File: DraggableItemView.m 
 Abstract: Part of the DraggableItemView project referenced in the 
 View Programming Guide for Cocoa documentation.
 
 Short Circuting the Event Loop Edition. 
  Version: 1.1 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "DraggableItemView.h"


@implementation DraggableItemView

// -----------------------------------
// Initialize the View
// -----------------------------------

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
	// setup the starting location of the 
	// draggable item
	[self setItemPropertiesToDefault:self];
    }
    return self;
}

// -----------------------------------
// Release the View
// -----------------------------------

- (void)dealloc
{
    // release the color items and set
    // the instance variables to nil
    [itemColor release];
    itemColor=nil;
    
    [backgroundColor release];
    backgroundColor=nil;
    
    // call super
    [super dealloc];  
}

// -----------------------------------
// Draw the View Content
// -----------------------------------

- (void)drawRect:(NSRect)rect
{
    // erase the background by drawing white
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:rect];
    
    // set the current color for the draggable item
    [[self itemColor] set];
    
    // draw the draggable item
    [NSBezierPath fillRect:[self calculatedItemBounds]];
}

- (BOOL)isOpaque
{
    // If the background color is opaque, return YES
    // otherwise, return NO
    return [[self backgroundColor] alphaComponent] >= 1.0 ? YES : NO;
}


// -----------------------------------
// Modify the item location 
// -----------------------------------

- (void)offsetLocationByX:(float)x andY:(float)y
{
    // tell the display to redraw the old rect
    [self setNeedsDisplayInRect:[self calculatedItemBounds]];
    
    // since the offset can be generated by both mouse moves
    // and moveUp:, moveDown:, etc.. actions, we'll invert
    // the deltaY amount based on if the view is flipped or 
    // not.
    int invertDeltaY = [self isFlipped] ? -1: 1;
    
    location.x=location.x+x;
    location.y=location.y+y*invertDeltaY;
    
    // invalidate the new rect location so that it'll
    // be redrawn
    [self setNeedsDisplayInRect:[self calculatedItemBounds]];
    
}

// -----------------------------------
// Hit test the item
// -----------------------------------

- (BOOL)isPointInItem:(NSPoint)testPoint
{
    BOOL itemHit=NO;
    
    // test first if we're in the rough bounds
    itemHit = NSPointInRect(testPoint,[self calculatedItemBounds]);
    
    // yes, lets further refine the testing
    if (itemHit) {
	
    }
    
    return itemHit;
}

// -----------------------------------
// Handle Mouse Events 
// -----------------------------------

// -----------------------------------
// Short Circuited mouseDown: handler
// -----------------------------------



-(void)mouseDown:(NSEvent *)event
{
    BOOL loop = YES;
    
    NSPoint clickLocation;
    
    // convert the initial click location into the view coords
    clickLocation = [self convertPoint:[event locationInWindow]
			      fromView:nil];
    
    // did the click occur in the draggable item?
    if ([self isPointInItem:clickLocation]) {
        // we're dragging, so let's set the cursor
	// to the closed hand
	[[NSCursor closedHandCursor] push];
	
	NSPoint newDragLocation;
	
	// the tight event loop pattern doesn't require the use
	// of any instance variables, so we'll use a local
	// variable localLastDragLocation instead.
	NSPoint localLastDragLocation;
	
	// save the starting location as the first relative point
	localLastDragLocation=clickLocation;
	
	while (loop) {
	    // get the next event that is a mouse-up or mouse-dragged event
	    NSEvent *localEvent;
	    localEvent= [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
	    
	    
	    switch ([localEvent type]) {
		case NSLeftMouseDragged:
		    
		    // convert the new drag location into the view coords
		    newDragLocation = [self convertPoint:[localEvent locationInWindow]
						fromView:nil];
		    
		    
		    // offset the item and update the display
		    [self offsetLocationByX:(float)(newDragLocation.x-localLastDragLocation.x)
				       andY:(float)(newDragLocation.y-localLastDragLocation.y)];
		    
		    // update the relative drag location;
		    localLastDragLocation=newDragLocation;
		    
		    // support automatic scrolling during a drag
		    // by calling NSView's autoscroll: method
		    [self autoscroll:localEvent];
		    
		    break;
		case NSLeftMouseUp:
		    // mouse up has been detected, 
		    // we can exit the loop
		    loop = NO;
		    
		    // finished dragging, restore the cursor
		    [NSCursor pop];
		    
		    // the rectangle has moved, we need to reset our cursor
		    // rectangle
		    [[self window] invalidateCursorRectsForView:self];
		    
		    break;
		default:
		    // Ignore any other kind of event. 
		    break;
	    }
	}
    };
    return;
}



// -----------------------------------
// First Responder Methods
// -----------------------------------

- (BOOL)acceptsFirstResponder
{
    return YES;
}



// -----------------------------------
// Handle KeyDown Events 
// -----------------------------------


- (void)keyDown:(NSEvent *)event
{
    BOOL handled = NO;
    NSString  *characters;
    
    // get the pressed key
    characters = [event charactersIgnoringModifiers];
    
    // is the "r" key pressed?
    if ([characters isEqual:@"r"]) {
	// Yes, it is
	handled = YES;
	
	// set the rectangle properties
	[self setItemPropertiesToDefault:self];
    }
    if (!handled)
	[super keyDown:event];
    
}

// -----------------------------------
// Handle NSResponder Actions 
// -----------------------------------

-(IBAction)moveUp:(id)sender
{
    [self offsetLocationByX:0.0f andY:10.0f];
    [[self window] invalidateCursorRectsForView:self];
}

-(IBAction)moveDown:(id)sender
{
    [self offsetLocationByX:0.0f andY:-10.0f];
    [[self window] invalidateCursorRectsForView:self];
}

-(IBAction)moveLeft:(id)sender
{
    [self offsetLocationByX:-10.0f andY:0.0f];
    [[self window] invalidateCursorRectsForView:self];
}

-(IBAction)moveRight:(id)sender
{
    [self offsetLocationByX:10.0f andY:0.0f];
    [[self window] invalidateCursorRectsForView:self];
}

- (IBAction)setItemPropertiesToDefault:(id)sender
{
    [self setLocation:NSMakePoint(0.0f,0.0f)];
    [self setItemColor:[NSColor redColor]];
    [self setBackgroundColor:[NSColor whiteColor]];
}



// -----------------------------------
// Handle color changes via first responder 
// -----------------------------------

- (void)changeColor:(id)sender
{
    // Set the color in response
    // to the color changing in the color panel.
    // get the new color by asking the sender, the color panel
    [self setItemColor:[sender color]];
}




// -----------------------------------
// Reset Cursor Rects 
// -----------------------------------

-(void)resetCursorRects
{
    // remove the existing cursor rects
    [self discardCursorRects];
    
    // add the draggable item's bounds as a cursor rect
    [self addCursorRect:[self calculatedItemBounds] cursor:[NSCursor openHandCursor]];
    
}

// -----------------------------------
//  Accessor Methods
// -----------------------------------

- (void)setItemColor:(NSColor *)aColor
{
	if (![itemColor isEqual:aColor]) {
        [itemColor release];
        itemColor = [aColor retain];
		
		// if the colors are not equal, mark the
		// draggable rect as needing display
        [self setNeedsDisplayInRect:[self calculatedItemBounds]];
    }
}


- (NSColor *)itemColor
{
    return [[itemColor retain] autorelease];
}

- (void)setBackgroundColor:(NSColor *)aColor
{
	if (![backgroundColor isEqual:aColor]) {
        [backgroundColor release];
        backgroundColor = [aColor retain];
		
		// if the colors are not equal, mark the
		// draggable rect as needing display
        [self setNeedsDisplayInRect:[self calculatedItemBounds]];
    }
}


- (NSColor *)backgroundColor
{
    return [[backgroundColor retain] autorelease];
}


- (void)setLocation:(NSPoint)point
{
    // test to see if the point actually changed
    if (!NSEqualPoints(point,location)) {
        // tell the display to redraw the old rect
	[self setNeedsDisplayInRect:[self calculatedItemBounds]];
	
        // reassign the rect
	location=point;
	
        // display the new rect
	[self setNeedsDisplayInRect:[self calculatedItemBounds]];
	
        // invalidate the cursor rects 
	[[self window] invalidateCursorRectsForView:self];
    }
}

- (NSPoint)location {
    return location;
}


- (NSRect)calculatedItemBounds
{
    NSRect calculatedRect;
    
    // calculate the bounds of the draggable item
    // relative to the location
    calculatedRect.origin=location;
    
    // the example assumes that the width and height
    // are fixed values
    calculatedRect.size.width=60.0f;
    calculatedRect.size.height=20.0f;
    
    return calculatedRect;
}





@end
