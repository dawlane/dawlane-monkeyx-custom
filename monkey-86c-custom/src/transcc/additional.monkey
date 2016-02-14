Import "native/os_ext.cpp"
Import transcc

#rem Dawlane modified
	Additional Functions and classes for compiler detections and transcc work files
	
	.........CLASS CBuildStatus.........
	LoadBuildFile:
		Load the last build file and store setting to a map
	
	SaveBuildFile:
		Save the last build file.
		
	GetKey:
		Retrieve a vale from the named key
		
	AddKey:
		Update or add a new named key with a value
		
	.........XCODE specific.........
	
	XCODEPath:
		Returns the current path of xcode
		
	XCODEVersion:
		Returns a string xcode version number or "error: problem"
		
	XCRUNCheck:
		From xcode 5 there is a little tool that makes working with xcode from the command line much easier.
		
	XCODEGetDeviceID:
		There are two version of this function:
			One requires just the device name and returns the UDID of the first device found.
			The other uses both the device name and SDK version stored in an array to locate the exact device.
		
	.........General.........
	Version2Array:
		Pass a string in the format major.minor.revision and returns an array breaking each into an integer number
	
	Version2String:
		Converts the passed array back int a string in the format major.minor(.revision). Note that revision is optional and passing True as a second argument includes it
		
	RetrieveOpt:
		Get an option from from a command line string.
		Returns either -1 for not found, start position of option or a right hand value if equal signed.
		Will not return rhs of options such as -x language
	
	GetMSize:
		General use is to parse for 32/64 options, but can be used to parse a single line by passing values to parameters 1 and 3
		Values returned are 32/64 for a match (single line returns 32), 0 for no match or -1 for mismatch if both of the given values are found in the
		strings to search i.e. string1=-m32 string2=-m64
		
	ErrorCodeFinder:
		Helper function to be used with ExecutePipe
		
	Execute:
		Executes an external process and redirects stdout and sdterr to a string. Pass an empty string to retrieve file stdout/stderr stream data.
		Note that error codes will not be consitant cross platforms.
	
#end

Class CBuildStatus

	Field map:= New StringMap<String>
	
	Method LoadFile:String( path:String="buildfile" )
		If FileType( path )<>FILETYPE_FILE Die "Error: File "+path+" not found."
		Local file:=LoadString( path ), equ:Int
		' Populate the string map
		For Local line:=Eachin file.Split( "~n" )
			If line<>""
				equ=line.Find( "=" )
				If equ=-1 Die "Error: no key/value pair at line "+line
				map.Add( line[ .. equ ], line[ equ+1 .. ] )
			Endif
		Next	
	End

	Method SaveFile:Void(path:String="buildfile")
		Local out:String=""
		For Local line:=Eachin map.Keys()
			If line<>"" out+=line+"="+map.Get( line )+"~n"
		Next
		SaveString( out, path )
		map.Clear()
	End
	
	Method GetKey:String( key:String )
		If map.Contains( key ) Return map.Get( key ) Else Return ""
	End
	
	Method AddKey:Void( key:String, val:String )
		If map.Contains( key ) map.Update( key, val ) Else map.Add( key, val )
	End
	
End

' XCODE specific functions
Function XCODEPath:String()	
	Local str:String
	If Execute( "xcode-select -p", str)<>0
		Print str
		Die "**** Error: There was an error executing xcode-selet to get the Xcode Path ****"
	Endif
	Return str.Trim()
End

Function XCODEVersion:Int[]()
	Local str:String, ver:Int[]
	If Execute( "xcodebuild -version", str )<>0
		Print str
		Die "**** Error: Unable to get Xcode version. Is Xcode installed? ****"
	Endif
	str=str[ 6 .. str.Find( "~n" )]
	ver=Version2Array( str.Trim() )
	Return ver
End
	
Function XCRUNCheck:Bool()
	Local str:String
	If os.Execute("xcrun -version")=0 Return True
	Return False
End

Function XCODEGetDeviceUDID:String( device:String )
	Local str:String, UDID:String
	If Execute( "instruments -s devices", str )<>0
		Print str
		Die "**** Error: There was an error executing instruments ****"
	Endif
	For Local line:=Eachin str.Split( "~n" )
		If line.Contains( device )
			str=line.Trim()
			Exit
		Else
			str=""
		Endif
	Next
	If str<>"" UDID=str[ str.Find("[")+1 .. str.Find( "]", str.Find("[")) ]
	Return UDID
End Function

Function XCODEGetDeviceUDID:String( device:String, sdk:Int[] )
	Local str:String, UDID:String, SDK:String
	SDK=Version2String( sdk )
	If Execute( "instruments -s devices", str )<>0
		Print str
		Die "**** Error: There was an error executing instruments ****"
	Endif
	For Local line:=Eachin str.Split( "~n" )
		If line.Contains( device ) And line.Contains( SDK )
			str=line.Trim()
			Exit
		Else
			str=""
		Endif
	Next
	If str<>"" UDID=str[ str.Find("[")+1 .. str.Find( "]", str.Find("[")) ]
	Return UDID
End Function

' Misc functions for GCC/MinGW/Visual Studio/Xcode
Function Version2Array:Int[]( str:String )
	Local ver:Int[3], index:Int, s1:Int, s2:Int
	While index < 3
		s2=str.Find( ".", s1 )
		If s2<0 s2=str.Length()
		ver[index]=Int(str[ s1 .. s2 ])
		s1=s2+1
		index+=1
	Wend
	Return ver
End Function

Function Version2String:String( ver:Int[], useRev:Bool=False )
	Local str:=ver[0]+"."+ver[1]
	If useRev str+="."+ver[2]
	Return str
End Function

Function RetrieveOpt:String(search:String, line:String, start=0, delimiter:String=" ")

	Local result:String=-1,i0:Int=start,i1:Int,i2:Int,i3:Int,opt:String
	
	While i0<line.Length()
		i1=line.Find(delimiter,i0)		
		If i1<0 i1=line.Length()		
		opt=line[i0 .. i1]
		i2=opt.Find("=")+1
		If i2>1 i3=i2 Else i3=i1		
		If Not search.Compare(opt[ .. i3])		
			If i2>1
				result=opt[i2..i1]
				Exit
			Endif			
			result=i0
			Exit			
		Endif
		i0=i1+1
	Wend
	
	Return result
End Function

Function GetMSize:Int(opt32:String,opt64:String="",cc_opts:String,ld_opts:String="",delimiter:String =" ")

	Local mCC:Int,mLD:Int
	
	If Int(RetrieveOpt(opt32,cc_opts,,delimiter))>-1 mCC=32 Else mCC=1
	If mCC=1 And opt64<>"" Then If Int(RetrieveOpt(opt64,cc_opts,,delimiter))>-1 mCC=64
	
	If ld_opts
		If Int(RetrieveOpt(opt32,ld_opts,,delimiter))>-1 mLD=32 Else mLD=1		
		If mLD=1 And opt64<>"" Then If Int(RetrieveOpt(opt64,ld_opts,,delimiter))>-1 mLD=64
		
		' Compare
		If ((mCC | mLD)&(~1))~96=0 Return -1	' Mismatch. Merge CC and LD and trap the top bits and exclusive or the bits to check.
		If (mCC & mLD)=32 Return 32				' Solid match
		If (mCC & mLD)=64 Return 64				' Solid match
		If (mCC & mLD)=1 Return 0				' No match, neither found
	Else
		If mCC>1 Then Return mCC
	Endif
	
	Return 0
End Function

Extern
	Function Execute( cmd$, ref$ )
Public
