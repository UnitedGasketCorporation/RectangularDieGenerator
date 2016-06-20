#SingleInstance off
#NoEnv
#Include, Gdip.ahk

Gdip_Startup()

;GDI+ is now started. Gdip.ahk must be in the script folder to run or compile. It does not need to be included with the compiled script.

; COLORS ARE transparency RED GREEN BLUE, FFFFFFFFFF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Create all the buttons and text in my gui ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;creating the text, text boxes, and buttons of my gui.
;use buttonName: to use buttons
Gui, Add, Text, x10 y10, Part Width
Gui, Add, Edit, x10 y25 w50 VPartWidth
Gui, Add, Text, x74 y10, Part Height
Gui, Add, Edit, x74 y25 w50 VPartHeight

Gui, Add, Text, x10 y53, Parts Horizontal
Gui, Add, Edit, x10 y68 w50 VPartsHor
Gui, Add, Text, x10 y96, Parts Vertical
Gui, Add, Edit, x10 y111 w50 VPartsVer

Gui, Add, Text, x10 y139, Horizontal Blade Tolerance
Gui, Add, Edit, x10 y154 w50 VHBladeTol, 0.125
Gui, Add, Text, x10 y182, Vertical Blade Tolerance
Gui, Add, Edit, x10 y197 w50 VVBladeTol, 0.125
Gui, Add, Text, x10 y225, Advance
Gui, Add, Edit, x10 y240 w50 VAdvance, 0.125

Gui, Add, Text, x10 y268, Rule Line Thickness
Gui, Add, Edit, x10 y283 w50 VRuleLineThick, 2
Gui, Add, Text, x10 y311, Dimension Line Thickness
Gui, Add, Edit, x10 y326 w50 VDimLineThick, 2

Gui, Add, Text, x10 y354, Rule Line Color
Gui, Add, Edit, x10 y369 w70 VRuleLineColor, Black
Gui, Add, Text, x94 y354, Dim Line Color
Gui, Add, Edit, x94 y369 w70 VDimLineColor, Red
Gui, Add, Text, x10 y397, BackgroundColor
Gui, Add, Edit, x10 y412 w70 VBackgroundColor, White
Gui, Add, Text, x10 y440, Scale
Gui, Add, Edit, x10 y455 w50 VDrawingScale, 100
Gui, Add, Text, x61 y458, `%

BackgroundColor := 0XFFFFFFFF

Gui, Add, Button, x10 y490 w70 default, Generate
Gui, Add, Button, x87 y490 w70, Save Image
Gui, Add, Button, x10 y520 w70, Clipboard
Gui, Add, Button, x87 y520 w70, Save DXF

Gui, Add, Text, x10 y555, Valid Colors Include:
Gui, Add, Text, X10 Y569, Black`nDark Grey`nGrey`nLight Grey`nWhite`nRed`nGreen`nBlue`nMagenta`nHexidecimal Values
Gui, Add, Text, X80 Y569, Yellow`nCyan`nOrange`nPink`nPurple`nBrown`nDark Red`nDark Green`nDark Blue


;drawing area is going to be w180-980 and h0-900
Gui, Show, w980 h900, Rectangle Felt Part Die Generator

;I have no clue exactly what this does but I need it. I think it gets the window position?
;Or maybe it gets the the ID of the window?
HWND := WinExist("A")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; more stuff idk what it does, but comments on other script says this is where gdip stuff starts ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hdc_WINDOW      := GetDC(HWND)                              ; MASTER DC on our Window
; We could draw on this DC directly, but its better and more comfortable to create a 
; 2nd DC, (as a frame) to  draw on. 
; So, If we want to show our Frame in the GUI, we have to copy (BitBlt) our Frame DC
; over the Window DC. This is done in the DRAW_SCENE Sub.


; This is our frame
hbm_main := CreateDIBSection(800, 900)              ; Size of GDI image in pixels. Width then height. Position defined later.
hdc_main := CreateCompatibleDC()
obm      := SelectObject(hdc_main, hbm_main)
G        := Gdip_GraphicsFromHDC(hdc_main)          ; Getting a Pointer to our bitmap

GoSub DrawBackground
GoSub DrawImage
return


ButtonGenerate:
Gui, Submit, NoHide
GoSub CheckDataIntegrity
If DataError = 1
{
	return
}
;Finally! now that all the input is checked and drawing functions are working, lets start doing the math that defines where stuff will go.
;First lets calculate how many vertical and horizontal lines I need
;PartsHor affects how many vertical blades I need
VerticalBladeCount := PartsHor + 1
HorizontalBladeCount := PartsVer + 1
DrawingScale := DrawingScale / 5       ;Then calculate the scale percentage into an easier to work with number Evey 1 unit will now take up 10 pixels at default scale.
Offset := 70       ; this will be my variable for offset from top and bottom in actual pixels.

GoSub DrawBackground    ;We need to be certian that this drawing starts with a blank canvas or it will just draw on top of other stuff.
;now we will draw the vertical lines with a bit of easy maths.
Loop %VerticalBladeCount%
{
	X1 := (((a_index * PartWidth) - PartWidth + HBladeTol) * DrawingScale) + Offset
	X2 := x1
	Y1 := Offset
	Y2 := Offset + (VBladeTol + VBladeTol + (PartHeight * PartsVer)) * DrawingScale
	GoSub DrawRuleLine
	
	If VerticalBladeCount = %a_index%
	{
		GoSub StoreXY
		Y1 := Y2            ;dim line 6
		Y2 := Y2
		X1 := X1 + 4
		X2 := X1 + 30 + HBladeTol * DrawingScale
		GoSub DrawDimLine
		GoSub LoadXY
		Y1 := Y1            ; dim line 7
		Y2 := Y1
		X1 := X1 + 4
		X2 := X1 + 92 + HBladeTol * DrawingScale
		GoSub DrawDimLine
		A7Y1 := Y1             ;arrow 7 parial
		GoSub LoadXY        ; dim line 8
		X1 := X1
		X2 := X1
		Y1 := Y1 - 4
		Y2 := Y1 - 20
		GoSub DrawDimLine
		GoSub LoadXY
		A3Y1 := Y2         ; arrow 3 partial
		;--
		A4X1 := X1 + 16     ; arrow 4 full
		A4X2 := X2 + 16
		A4Y1 := Y1
		A4Y2 := Y2
		;--
		A5X1 := X1 - PartWidth * DrawingScale
		A5X2 := X2                                  ; arrow 5 full
		A5Y1 := Y1 - 16
		A5Y2 := Y1 - 16

		X1 := X1 - PartWidth * DrawingScale          ;dim line 9
		X2 := X1
		Y1 := Y1 - 4
		Y2 := Y1 - 20
		GoSub DrawDimLine
		
		
		
	}
}

;Now to draw the horizontal lines
Loop %HorizontalBladeCount%
{
	X1 := Offset
	X2 := Offset + (HBladeTol + HBladeTol + (PartWidth * PartsHor)) * DrawingScale
	Y1 := Offset + (PartsVer * PartHeight - PartHeight + a_index * PartHeight + VBladeTol * 3 + Advance) * DrawingScale
	Y2 := Y1
	GoSub DrawRuleLine
	If HorizontalBladeCount = %a_index%   ;This If and any after it within this loop draw dimension lines depending on the current die line
	{
		GoSub StoreXY
		X1 := X1          ;dim line 1
		X2 := X1
		Y1 := Y1 + 4
		Y2 := Y1 + 20
		GoSub DrawDimLine
		GoSub LoadXY
		X1 := X2         ; dim line 2
		X2 := X2
		Y1 := Y1 + 4
		Y2 := Y1 + 20
		GoSub DrawDimLine
		GoSub LoadXY
		A1X1 := X1         ; arrow 1 full
		A1X2 := X2
		A1Y1 := Y1 + 16
		A1Y2 := Y1 + 16
		;--
		A2X1 := X2 + 16    ; arrow 2 parial
		A2X2 := X2 + 16
		A2Y2 := Y1     
		X1 := X2 + 4      ; dim line 3
		X2 := x2 + 96
		Y1 := Y1
		Y2 := Y2
		GoSub DrawDimLine
		A7X1 := X2 - 8     ; arrow 7 partial
		A7X2 := A7X1
		A7Y2 := Y1
		
	}
	
	If HorizontalBladeCount - 1 = a_index
	{
		GoSub StoreXY
		X1 := X2 + 4      ; dim line 4
		X2 := x2 + 24
		Y1 := Y1
		Y2 := Y2
		GoSub DrawDimLine	
		A2Y1 := Y1         ;arrow 2 parial
		GoSub LoadXY
	}
	If a_index = 1
	{
		GoSub StoreXY
		X1 := X2 + 4      ; dim line 5
		X2 := x2 + 34
		Y1 := Y1
		Y2 := Y2
		GoSub DrawDimLine	
		GoSub LoadXY
		A3X1 := X2 + 26   ; arrow 3 partial
		A3X2 := X2 + 26
		A3Y2 := Y1
		X1 := X1            ;dim line 10
		X2 := X1
		Y2 := Y1 - 4 
		Y1 := Y1 - 24 - VBladeTol * Advance
		GoSub DrawDimLine
		A6Y1 := Y1 + 8
		A6Y2 := Y1 + 8
		A6X1 := X1
		A6X2 := X1 + HBladeTol * DrawingScale
	}
}

;Draw Arrow #1
X1 := A1X1
X2 := A1X2
Y1 := A1Y1
Y2 := A1Y2
Size := 3 + DimLineThick * 1.7
GoSub DrawArrow

;Draw Arrow #2
X1 := A2X1
X2 := A2X2
Y1 := A2Y1
Y2 := A2Y2
Size := 3 + DimLineThick * 1.7
GoSub DrawArrow

;Draw Arrow #3
X1 := A3X1
X2 := A3X2
Y1 := A3Y1
Y2 := A3Y2
Size := 3 + DimLineThick * 1.7
GoSub DrawArrowOut

;Draw Arrow #4
X1 := A4X1
X2 := A4X2
Y1 := A4Y1
Y2 := A4Y2
Size := 3 + DimLineThick * 1.7
GoSub DrawArrow

;Draw Arrow #5
X1 := A5X1
X2 := A5X2
Y1 := A5Y1
Y2 := A5Y2
Size := 3 + DimLineThick * 1.7
GoSub DrawArrow

;Draw Arrow #6
X1 := A6X1
X2 := A6X2
Y1 := A6Y1
Y2 := A6Y2
Size := 3 + DimLineThick * 1.7
GoSub DrawArrowOut

;Draw Arrow #7
X1 := A7X1
X2 := A7X2
Y1 := A7Y1
Y2 := A7Y2
Size := 3 + DimLineThick * 1.7
GoSub DrawArrow

;now to calculate what each dimension should be per arrow

A1DIM := PartWidth * PartsHor + HBladeTol * 2
A2DIM := PartHeight
A3DIM := VBladeTol + Advance
A4DIM := PartHeight * PartsVer + VBladeTol * 2
A5DIM := PartWidth
A6DIM := HBladeTol
A7DIM := VBladeTol * 3 + (PartHeight * PartsVer) * 2 + Advance

;Making sure all numbers have 3 decimal places. There is probably a better method than adding and subtracting to every variable!
SetFormat, Float, 7.3 ;all following math now has minimum 7 characters(inclusing decimal) and always 3 after dicimal. Any space needed to fill such as 2.012 fills with spaces like "  2.012"
A1DIM := A1DIM + 0.1  ;the spaces are needed to keep number lined up
A1DIM := A1DIM - 0.1  ;this math reduces accuracy of math to only 3 decimals so we will only do the bare minimum math here.
A2DIM := A2DIM + 0.1
A2DIM := A2DIM - 0.1
A3DIM := A3DIM + 0.1
A3DIM := A3DIM - 0.1
A4DIM := A4DIM + 0.1
A4DIM := A4DIM - 0.1
A5DIM := A5DIM + 0.1
A5DIM := A5DIM - 0.1
A6DIM := A6DIM + 0.1
A6DIM := A6DIM - 0.1
A7DIM := A7DIM + 0.1
A7DIM := A7DIM - 0.1
SetFormat, Float, 0.3  ;we want the next number to have 3 decimals but it doesn't need leading spaces.
AdvanceText := PartHeight * PartsVer + Advance + VBladeTol * 2
SetFormat, Float, 0.8   ;all following math now has no minimum characters and 7

;trimming the 0x off DimLineColor so I can use it for text
StringTrimLeft, TrimmedColor, DimLineColor, 2  ;removes two characters from the left (0 and x)

;Text for dimensions arrows in order 1 to 6.
TextX := (A1X1 + A1X2) / 2 - 35 
TextY := A1Y1 + 10
Font = Arial
ColorToTrim := 
Options := "x" . TextX . "y" . TextY . " c" . TrimmedColor . " r4 s16"
Message := A1DIM
GoSub DrawText

Message := "Advance is " . AdvanceText ;quick, while I'm at the bottom, draw the text telling the advance!
TextX := Offset
TextY := TextY + 20
Options := "x" . TextX . "y" . TextY . " c" . TrimmedColor . " r4 s16"
GoSub DrawText

BitmapHeight := TextY + 30     ;calculate height of bitmap while I already have most of the math done.

;now for dimension 2
TextX := A2X1 + 3
TextY := (A2Y1 + A2Y2) / 2 - 7
Font = Arial
Options := "x" . TextX . "y" . TextY . " c" . TrimmedColor . " r4 s16"
Message := A2DIM
GoSub DrawText

;now for dimension 3
TextX := A3X1 + 3
TextY := (A3Y1 + A3Y2) / 2 - 7
Font = Arial
Options := "x" . TextX . "y" . TextY . " c" . TrimmedColor . " r4 s16"
Message := A3DIM
GoSub DrawText

;now for dimension 4
TextX := A4X1 + 3
TextY := (A4Y1 + A4Y2) / 2 - 7
Font = Arial
Options := "x" . TextX . "y" . TextY . " c" . TrimmedColor . " r4 s16"
Message := A4DIM
GoSub DrawText

;now for dimension 5
TextX := (A5X1 + A5X2) / 2 - 35
TextY := A5Y1 - 25
Font = Arial
Options := "x" . TextX . "y" . TextY . " c" . TrimmedColor . " r4 s16"
Message := A5DIM
GoSub DrawText

;now for dimension 6
TextX := A6X1 - 65
TextY := A6Y1 - 7
Font = Arial
Options := "x" . TextX . "y" . TextY . " c" . TrimmedColor . " r4 s16"
Message := A6DIM
GoSub DrawText

;now for dimension 7
TextX := A7X1 + 3
TextY := (A7Y1 + A7Y2) / 2 - 7
Font = Arial
Options := "x" . TextX . "y" . TextY . " c" . TrimmedColor . " r4 s16"
Message := A7DIM
GoSub DrawText

BitmapWidth := TextX + 75   ;Calculate bitmap while I have most of the math needed done.





GoSub DrawImage

Return



CheckDataIntegrity:
	DataError = 0
	ErrorMessage := "There are some errors with your data input."
	If PartWidth <= 0
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nPart Width must be greater than 0."
	}
	If PartHeight <= 0
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nPart Height must be greater than 0."
	}
	If PartsHor <= 0
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nParts Horizontal must be greater than 0."
	}
	If PartsVer <= 0
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nParts Vertical must be greater than 0."
	}
	If HBladeTol < 0
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nHorizontal Blade Tolerance must be at least 0."
	}
	If VBladeTol < 0
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nVertical Blade Tolerance must be at least 0."
	}
	If Advance < 0
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nHorizontal Blade Tolerance must be at least 0."
	}
	If RuleLineThick < 1
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nRule Line Thickness must be at least 1."
	}
	If DimLineThick < 1
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nDimension Line Thickness must be at least 1."
	}
	If DrawingScale <= 0
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nScale Percentage must be greater than 0."
	}

	ColorInput := RuleLineColor           ;converts color text to hex for the script
	GoSub ConvertColorToHex               ;and checks for an error.
	RuleLineColor := ColorOutput
	If !CorrectSyntax     ;check if string is empty. If it is that means there is an error.
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nRule Line Color is invalid. Check the list of valid colors."
	}
	
	ColorInput := DimLineColor
	GoSub ConvertColorToHex
	DimLineColor := ColorOutput
	If !CorrectSyntax
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nDim Line Color is invalid. Check the list of valid colors."
	}
	
	ColorInput := BackgroundColor
	GoSub ConvertColorToHex
	BackgroundColor := ColorOutput
	If !CorrectSyntax
	{
		DataError = 1
		ErrorMessage := ErrorMessage . "`nBackground Color is invalid. Check the list of valid colors."
	}

	
	If DataError = 1
	{
		ErrorMessage := ErrorMessage . "`n`nPlease fix these errors then click Generate again to continue."
		ErrorBgBrush := Gdip_BrushCreateSolid(0XFFFFFFFF)
		Gdip_FillRectangle(G,ErrorBgBrush,0,0,800,900)
		Font = Arial
		Options = x10 y10 cff550000 r4 s20
		Message := ErrorMessage
		GoSub DrawText
		GoSub DrawImage
	}
Return

ConvertColorToHex:
	ColorOutput := ColorInput
	If ColorInput = Black
	{
		ColorOutput := "0xFF000000"
	}
	If ColorInput = Dark Grey
	{
		ColorOutput := "0xFF404040"
	}
	If ColorInput = Grey
	{
		ColorOutput := "0xFF808080"
	}
	If ColorInput = Light Grey
	{
		ColorOutput := "0xFFBFBFBF"
	}
	If ColorInput = White
	{
		ColorOutput := "0xFFFFFFFF"
	}
	If ColorInput = Red
	{
		ColorOutput := "0xFFFF0000"
	}
	If ColorInput = Green
	{
		ColorOutput := "0xFF00FF00"
	}
	If ColorInput = Blue
	{
		ColorOutput := "0xFF0000FF"
	}
	If ColorInput = Magenta
	{
		ColorOutput := "0xFFFF00FF"
	}
	If ColorInput = Yellow
	{
		ColorOutput := "0xFFFFFF00"
	}
	If ColorInput = Cyan
	{
		ColorOutput := "0xFF00FFFF"
	}
	If ColorInput = Orange
	{
		ColorOutput := "0xFFFF7F00"
	}
	If ColorInput = Pink
	{
		ColorOutput := "0xFFFF7FFF"
	}
	If ColorInput = Purple
	{
		ColorOutput := "0xFF7F00FF"
	}
	If ColorInput = Brown
	{
		ColorOutput := "0xFF9C5314"
	}
	If ColorInput = Dark Red
	{
		ColorOutput := "0xFF7F0000"
	}
	If ColorInput = Dark Green
	{
		ColorOutput := "0xFF007F00"
	}
	If ColorInput = Dark Blue
	{
		ColorOutput := "0xFF00007F"
	}
	CorrectSyntax := RegExMatch(ColorOutput,"[0][Xx][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]")   ;looks for 0 then x or X then 8 of a correct hex number
Return

ButtonSaveImage:        ;saves the image to the user's chosen directory and file name, defaulting to desktop.
	Gui, Submit, NoHide
	GoSub ButtonGenerate
	GoSub CheckDataIntegrity
	If DataError = 0
	{
		FileSelectFile, BMPFileName, S16 , %A_Desktop%\GeneratedDie.bmp, Save Image, Bitmap(*.bmp)   ;option S16, S = Save, 16 = Prompt overwrite
		If ErrorLevel = 1     ;if user pressed cancel
		{
			Return
		}	
		pBitmap := Gdip_CreateBitmap(BitmapWidth, BitmapHeight)
		G := Gdip_GraphicsFromImage(pBitmap)       ;sets graphic mode to something else so I can save a bitmap?
		GoSub ButtonGenerate                       ;I have no damn clue how to use this stuff... But it's working now so I'll leave it.
		Gdip_SaveBitmapToFile(pBitmap, BMPFileName)
		G := Gdip_GraphicsFromHDC(hdc_main)   ;sets graphic mode back to the correct kind?
	}
	DataError = 0
Return

ButtonClipboard:      ;there must be a better method, but this is what I did because it was easy. It saves the bitmap to the script directory then copies it to the clipboard.
	Gui, Submit, NoHide
	GoSub ButtonGenerate
	GoSub CheckDataIntegrity
	If DataError = 0
	{
		pBitmap := Gdip_CreateBitmap(BitmapWidth, BitmapHeight)
		G := Gdip_GraphicsFromImage(pBitmap)       ;sets graphic mode to something else so I can save a bitmap?
		GoSub ButtonGenerate                       ;I have no damn clue how to use this stuff... But it's working now so I'll leave it.
		Gdip_SaveBitmapToFile(pBitmap, "DieGeneratorTemp-88572943.bmp")
		G := Gdip_GraphicsFromHDC(hdc_main)   ;sets graphic mode back to the correct kind?
		Gdip_SetBitmapToClipboard(pBitmap)
		FileDelete, DieGeneratorTemp-88572943.bmp
	}
	DataError = 0
Return

;Saving as a DXF is going to be a loooong script because it has to redo all the work I did before to draw lines, except now it needs to generate DXF stuff.
ButtonSaveDXF:
	Gui, Submit, NoHide
	GoSub ButtonGenerate
	GoSub CheckDataIntegrity
	If DataError = 0
	{
	FileSelectFile, DXFFileName, S16 , %A_Desktop%\GeneratedDie.DXF, Save DXF, DXF CAD File(*.DXF)   ;option S16, S = Save, 16 = Prompt overwrite
	If ErrorLevel = 1     ;if user pressed cancel
	{
		Return
	}
	IfExist, %DXFFileName%
	{
		FileDelete, %DXFFileName%
	}
	    ;writing the first part of the file, the header. Next will be separate lines.
	FileAppend,
	(
	999
File Created by United Gasket's rectangle parts die generator by Michael B
0
SECTION
2
HEADER
9
$ACADVER
1
AC1006
9
$INSBASE
10
0.0
20
0.0
30
0.0
9
$EXTMIN
10
0.0
20
0.0
9
$EXTMAX
10
10000.0
20
10000.0
0
ENDSEC
0
SECTION
2
ENTITIES
0
), %DXFFileName%
	
	;time to do some math to draw the lines in the DXF. Sorry, no dimensions!
	VerticalBladeCount := PartsHor + 1
	HorizontalBladeCount := PartsVer + 1
	Loop %VerticalBladeCount%
	{
		X1 := 15-((a_index * PartWidth) - PartWidth + HBladeTol)
		X2 := x1
		Y1 := 15-0
		Y2 := 15-(VBladeTol + VBladeTol + (PartHeight * PartsVer))
		GoSub AddLineToDXF
	}
	Loop %HorizontalBladeCount%
	{
		X1 := 15-0
		X2 := 15-(HBladeTol + HBladeTol + (PartWidth * PartsHor))
		Y1 := 15-(PartsVer * PartHeight - PartHeight + a_index * PartHeight + VBladeTol * 3 + Advance)
		Y2 := Y1
		GoSub AddLineToDXF
	}
	FileAppend,
	(
	
ENDSEC
0
EOF
),  %DXFFileName%
	}
	DataError = 0
Return

AddLineToDXF:
	FileAppend,
	(
	
LINE
8
0
10
%X1%
20
%Y1%
30
0
11
%X2%
21
%Y2%
31
0
0
), %DXFFileName%
Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Drawing functions below this;;                ++++++++++++++++++++++++++
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


StoreXY:
	X1Temp := X1
	X2Temp := X2
	Y1Temp := Y1
	Y2Temp := Y2
Return

LoadXY:
	X1 := X1Temp
	X2 := X2Temp
	Y1 := Y1Temp
	Y2 := Y2Temp
Return

DrawText:
	;Font = Arial
	;Options = x10 y10 cff550000 r4 s20
	Gdip_FontFamilyCreate(Font)
	Gdip_TextToGraphics(G, Message, Options)	
Return

;this draws the background
DrawBackground:
	bgBrush := Gdip_BrushCreateSolid(BackgroundColor) ;defining brush color
	Gdip_FillRectangle(G,bgBrush,0,0,800,900)    ;drawing a rectangle (x1, y1, x2, y2)
Return

DrawArrow:
	;don't forget x1, x2, y1, y2, size. Uses Dim Line color and thickness
	LineBrush := Gdip_CreatePen(DimLineColor,DimLineThick)
	Gdip_DrawLine(G,LineBrush, X1, Y1, X2, Y2)
	If X1 = %X2%
	{
		AX1 := X1
		AX2 := X1 - Size
		AX3 := X1 + Size
		AY1 := Y1
		If Y1 > %Y2%
		{
			AY2 := Y1 - Size
			AY4 := Y2
		}
		Else
		{
			AY2 := Y1 + Size
			AY4 := Y2
		}
		AY3 := Y2 - Size
		Gdip_SetSmoothingMode(G, 4)
		Gdip_DrawLine(G,LineBrush, AX2, AY2, AX1, AY1)
		Gdip_DrawLine(G,LineBrush, AX1, AY1, AX3, AY2)
		Gdip_DrawLine(G,LineBrush, AX2, AY3, AX1, AY4)
		Gdip_DrawLine(G,LineBrush, AX3, AY3, AX1, AY4)
		Gdip_SetSmoothingMode(G, 0)
	}
	If Y1 = %Y2%
	{
		AY1 := Y1
		AY2 := Y1 - Size
		AY3 := Y1 + Size
		AX1 := X1
		AX3 := X2
		If X1 > %X2%
		{
			AX2 := X1 + Szie
			AX4 := X2 - Size
		}
		Else
		{
			AX2 := X1 + Size
			Ax4 := X2 - Size
		}
		Gdip_SetSmoothingMode(G, 4)
		Gdip_DrawLine(G,LineBrush, AX1, AY1, AX2, AY2)
		Gdip_DrawLine(G,LineBrush, AX1, AY1, AX2, AY3)
		Gdip_DrawLine(G,LineBrush, AX3, AY1, AX4, AY2)
		Gdip_DrawLine(G,LineBrush, AX3, AY1, AX4, AY3)
		Gdip_SetSmoothingMode(G, 0)
	}
Return

DrawArrowOut:
	;don't forget x1, x2, y1, y2, size. Uses Dim Line color and thickness
	LineBrush := Gdip_CreatePen(DimLineColor,DimLineThick)
	If X1 = %X2%
	{
		AX1 := X1
		AX2 := X1 + Size
		AX3 := X1 - Size
		AY1 := Y1
		If Y1 > %Y2%
		{
			AY2 := Y1 + Size
			AY4 := Y2
		}
		Else
		{
			AY2 := Y1 - Size
			AY4 := Y2
		}
		AY3 := Y2 + Size
		Gdip_SetSmoothingMode(G, 4)
		Gdip_DrawLine(G,LineBrush, AX2, AY2, AX1, AY1)
		Gdip_DrawLine(G,LineBrush, AX1, AY1, AX3, AY2)
		Gdip_DrawLine(G,LineBrush, AX2, AY3, AX1, AY4)
		Gdip_DrawLine(G,LineBrush, AX3, AY3, AX1, AY4)
		Gdip_SetSmoothingMode(G, 0)
	}
	If Y1 = %Y2%
	{
		AY1 := Y1
		AY2 := Y1 + Size
		AY3 := Y1 - Size
		AX1 := X1
		AX3 := X2
		If X1 > %X2%
		{
			AX2 := X1 + Szie
			AX4 := X2 - Size
		}
		Else
		{
			AX2 := X1 - Size
			Ax4 := X2 + Size
		}
		Gdip_SetSmoothingMode(G, 4)
		Gdip_DrawLine(G,LineBrush, AX1, AY1, AX2, AY2)
		Gdip_DrawLine(G,LineBrush, AX1, AY1, AX2, AY3)
		Gdip_DrawLine(G,LineBrush, AX3, AY1, AX4, AY2)
		Gdip_DrawLine(G,LineBrush, AX3, AY1, AX4, AY3)
		Gdip_SetSmoothingMode(G, 0)
	}
Return

DrawDimLine:
	LineBrush := Gdip_CreatePen(DimLineColor,DimLineThick)
	Gdip_DrawLine(G,LineBrush, X1, Y1, X2, Y2)
Return

DrawRuleLine:
	LineBrush := Gdip_CreatePen(RuleLineColor,RuleLineThick)
	Gdip_DrawLine(G,LineBrush, X1, Y1, X2, Y2)
Return

;this draws whatever has been done so far
DrawImage:
	BitBlt(hdc_WINDOW, 180, 0, 800,900, hdc_main,0,0) ;position of the GDI Image in the GUI (?, posH, posV, W, L, ?)
return

Exit:
GuiClose:
GuiEscape:
ExitApp