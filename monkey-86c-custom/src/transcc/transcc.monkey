' stdcpp app 'transcc' - driver program for the Monkey translator.
'
' Placed into the public domain 24/02/2011.
' No warranty implied; use at your own risk.

Import trans
Import builders
Import additional

' Dawlane modified. Just in case there is a 64 bit version of MinGW installed and a 32bit is required
'	#CC_OPTS="-m32"

'#CC_OPTS+=" -s" ' Uncomment to strip the executable of symbols for release. Windows and Linux only.Throws error on OS X
#CC_OUT_FILENAME="transcc"

' Dawlane modified. Use to load and save a last build status file
Global BuildStatus:CBuildStatus = New CBuildStatus

Const VERSION:="1.86"
Const DAWLANE_MOD_VER:="0.04"

Function Main()
	Local tcc:=New TransCC
	tcc.Run AppArgs
End

Function Die( msg:String )
	Print "TRANS FAILED: "+msg
	ExitApp -1
End

Function StripQuotes:String( str:String )
	If str.Length>=2 And str.StartsWith( "~q" ) And str.EndsWith( "~q" ) Return str[1..-1]
	Return str
End

Function ReplaceEnv:String( str:String )
	Local bits:=New StringStack

	Repeat
		Local i=str.Find( "${" )
		If i=-1 Exit

		Local e=str.Find( "}",i+2 ) 
		If e=-1 Exit
		
		If i>=2 And str[i-2..i]="//"
			bits.Push str[..e+1]
			str=str[e+1..]
			Continue
		Endif
		
		Local t:=str[i+2..e]

		Local v:=GetConfigVar(t)
		If Not v v=GetEnv(t)
		
		bits.Push str[..i]
		bits.Push v
		
		str=str[e+1..]
	Forever
	If bits.IsEmpty() Return str
	
	bits.Push str
	Return bits.Join( "" )
End

Function ReplaceBlock:String( text:String,tag:String,repText:String,mark:String="~n//" )

	'find begin tag
	Local beginTag:=mark+"${"+tag+"_BEGIN}"
	Local i=text.Find( beginTag )
	If i=-1 Die "Error updating target project - can't find block begin tag '"+tag+"'. You may need to delete target .build directory."
	i+=beginTag.Length
	While i<text.Length And text[i-1]<>10
		i+=1
	Wend
	
	'find end tag
	Local endTag:=mark+"${"+tag+"_END}"
	Local i2=text.Find( endTag,i-1 )
	If i2=-1 Die "Error updating target project - can't find block end tag '"+tag+"'."
	If Not repText Or repText[repText.Length-1]=10 i2+=1
	
	Return text[..i]+repText+text[i2..]
End

Function MatchPathAlt:Bool( text:String,alt:String )

	If Not alt.Contains( "*" ) Return alt=text
	
	Local bits:=alt.Split( "*" )
	If Not text.StartsWith( bits[0] ) Return False

	Local n:=bits.Length-1
	Local i:=bits[0].Length
	For Local j:=1 Until n
		Local bit:=bits[j]
		i=text.Find( bit,i )
		If i=-1 Return False
		i+=bit.Length
	Next

	Return text[i..].EndsWith( bits[n] )
End

Function MatchPath:Bool( text:String,pattern:String )

	text="/"+text
	Local alts:=pattern.Split( "|" )
	Local match:=False

	For Local alt:=Eachin alts
		If Not alt Continue
		
		If alt.StartsWith( "!" )
			If MatchPathAlt( text,alt[1..] ) Return False
		Else
			If MatchPathAlt( text,alt ) match=True
		Endif
	Next
	
	Return match
End

Class Target
	Field dir:String
	Field name:String
	Field system:String
	Field builder:Builder
	
	Method New( dir:String,name:String,system:String,builder:Builder )
		Self.dir=dir
		Self.name=name
		Self.system=system
		Self.builder=builder
	End
End

Class TransCC

	'cmd line args
	Field opt_safe:Bool
	Field opt_clean:Bool
	Field opt_check:Bool
	Field opt_update:Bool
	Field opt_build:Bool
	Field opt_run:Bool

	Field opt_srcpath:String
	Field opt_cfgfile:String
	Field opt_output:String
	Field opt_config:String
	Field opt_casedcfg:String
	Field opt_target:String
	Field opt_modpath:String
	Field opt_builddir:String
	' Dawlane modified MinGW32 cross-compiler & CPU Architecture
	Field opt_mingw32cross:Bool	
	Field opt_msize:String
	
	'config file
	Field ANDROID_PATH:String
	Field ANDROID_NDK_PATH:String
	Field ANT_PATH:String
	Field JDK_PATH:String
	Field FLEX_PATH:String
	Field MINGW_PATH:String
	Field MSBUILD_PATH:String
	Field PSS_PATH:String
	Field PSM_PATH:String
	Field HTML_PLAYER:String
	Field FLASH_PLAYER:String
	' Dawlane modified MinGW32 cross-compiler
	Field MINGW_TOOLCHAIN:String
	
	Field args:String[]
	Field monkeydir:String
	Field target:Target
	
	Field _builders:=New StringMap<Builder>
	Field _targets:=New StringMap<Target>
	
	Method Run:Void( args:String[] )

		Self.args=args
		
		' Dawlane modified MinGW32 cross-compiler & CPU Architecture
		If HostOS="winnt"
			Print "TRANS monkey compiler V"+VERSION+" (Dawlane Custom v"+DAWLANE_MOD_VER+")"
		Else
			Print "TRANS monkey compiler V"+VERSION+" (Dawlane Custom with MinGW support v"+DAWLANE_MOD_VER+")"
		Endif
	
		monkeydir=RealPath( ExtractDir( AppPath )+"/.." )

		SetEnv "MONKEYDIR",monkeydir
		SetEnv "TRANSDIR",monkeydir+"/bin"
	
		ParseArgs
		
		LoadConfig
		
		EnumBuilders
		
		EnumTargets "targets"
		
		If args.Length<2
			Local valid:=""
			For Local it:=Eachin _targets
				valid+=" "+it.Key.Replace( " ","_" )
			Next
			' Dawlane modified Linux MinGW32 cross-compiler & CPU Architecture
			If HostOS="linux" Or HostOS="macos" Then
				Print "TRANS Usage: transcc [-msize=32/64] [-mingw32cross] [-update] [-build] [-run] [-clean] [-config=...] [-target=...] [-cfgfile=...] [-modpath=...] <main_monkey_source_file>"
			Else
				Print "TRANS Usage: transcc [-msize=32/64] [-update] [-build] [-run] [-clean] [-config=...] [-target=...] [-cfgfile=...] [-modpath=...] <main_monkey_source_file>"
			Endif
			Print "Valid targets:"+valid
			Print "Valid configs: debug release"
			ExitApp 0
		Endif
		
		target=_targets.Get( opt_target.Replace( "_"," " ) )
		If Not target Die "Invalid target"
		
		target.builder.Make
	End

	Method GetReleaseVersion:String()
		Local f:=LoadString( monkeydir+"/VERSIONS.TXT" )
		For Local t:=Eachin f.Split( "~n" )
			t=t.Trim()
			If t.StartsWith( "***** v" ) And t.EndsWith( " *****" ) Return t[6..-6]
		Next
		Return ""
	End
	
	Method EnumBuilders:Void()
		For Local it:=Eachin Builders( Self )
			If it.Value.IsValid() _builders.Set it.Key,it.Value
		Next
	End
	
	Method EnumTargets:Void( dir:String )
	
		Local p:=monkeydir+"/"+dir
		
		For Local f:=Eachin LoadDir( p )
			Local t:=p+"/"+f+"/TARGET.MONKEY"
			If FileType(t)<>FILETYPE_FILE Continue
			
			PushConfigScope
			
			PreProcess t
			
			Local name:=GetConfigVar( "TARGET_NAME" )
			If name
				Local system:=GetConfigVar( "TARGET_SYSTEM" )
				If system
					Local builder:=_builders.Get( GetConfigVar( "TARGET_BUILDER" ) )
					If builder
						Local host:=GetConfigVar( "TARGET_HOST" )
						If Not host Or host=HostOS
							_targets.Set name,New Target( f,name,system,builder )
						Endif
					Endif
				Endif
			Endif
			
			PopConfigScope
			
		Next
	End
	
	Method ParseArgs:Void()
	
		If args.Length>1 opt_srcpath=StripQuotes( args[args.Length-1].Trim() )
	
		For Local i:=1 Until args.Length-1
		
			Local arg:=args[i].Trim(),rhs:=""
			Local j:=arg.Find( "=" )
			If j<>-1
				rhs=StripQuotes( arg[j+1..] )
				arg=arg[..j]
			Endif
		
			If j=-1
				Select arg.ToLower()
				Case "-safe"
					opt_safe=True
				Case "-clean"
					opt_clean=True
				Case "-check"
					opt_check=True
				Case "-update"
					opt_check=True
					opt_update=True
				Case "-build"
					opt_check=True
					opt_update=True
					opt_build=True
				Case "-run"
					opt_check=True
					opt_update=True
					opt_build=True
					opt_run=True
				' Dawlane modified Linux MinGW32 cross-compiler
				Case "-mingw32cross"
					opt_mingw32cross=True
				Default
					Die "Unrecognized command line option: "+arg
				End
			Else If arg.StartsWith( "-" )
				Select arg.ToLower()
				Case "-cfgfile"
					opt_cfgfile=rhs
				Case "-output"
					opt_output=rhs
				Case "-config"
					opt_config=rhs.ToLower()
				Case "-target"
					opt_target=rhs
				Case "-modpath"
					opt_modpath=rhs
				Case "-builddir"
					opt_builddir=rhs
				' Dawlane Modified CPU architecture
				Case "-msize"
					opt_msize=rhs
				Default
					Die "Unrecognized command line option: "+arg
				End
			Else If arg.StartsWith( "+" )
				SetConfigVar arg[1..],rhs
			Else
				Die "Command line arg error: "+arg
			End
		Next
		
	End

	Method LoadConfig:Void()
	
		Local cfgpath:=monkeydir+"/bin/"
		If opt_cfgfile 
			cfgpath+=opt_cfgfile
		Else
			cfgpath+="config."+HostOS+".txt"
		Endif
		If FileType( cfgpath )<>FILETYPE_FILE Die "Failed to open config file"
	
		Local cfg:=LoadString( cfgpath )
			
		For Local line:=Eachin cfg.Split( "~n" )
		
			line=line.Trim()
			If Not line Or line.StartsWith( "'" ) Continue
			
			Local i=line.Find( "=" )
			If i=-1 Die "Error in config file, line="+line
			
			Local lhs:=line[..i].Trim()
			Local rhs:=line[i+1..].Trim()
			
			rhs=ReplaceEnv( rhs )
			
			Local path:=StripQuotes( rhs )
	
			While path.EndsWith( "/" ) Or path.EndsWith( "\" ) 
				path=path[..-1]
			Wend
			
			Select lhs
			Case "MODPATH"
				If Not opt_modpath
					opt_modpath=path
				Endif
			Case "ANDROID_PATH"
				If Not ANDROID_PATH And FileType( path )=FILETYPE_DIR
					ANDROID_PATH=path
				Endif
			Case "ANDROID_NDK_PATH"
				If Not ANDROID_NDK_PATH And FileType( path )=FILETYPE_DIR
					ANDROID_NDK_PATH=path
				Endif
			Case "JDK_PATH" 
				If Not JDK_PATH And FileType( path )=FILETYPE_DIR
					JDK_PATH=path
				Endif
			Case "ANT_PATH"
				If Not ANT_PATH And FileType( path )=FILETYPE_DIR
					ANT_PATH=path
				Endif
			Case "FLEX_PATH"
				If Not FLEX_PATH And FileType( path )=FILETYPE_DIR
					FLEX_PATH=path
				Endif
			Case "MINGW_PATH"
				' Dawlane Modified for MinGw Cross-Compiler path for Mac OS X and Windows
				If Not MINGW_PATH And FileType( path )=FILETYPE_DIR And (HostOS="winnt" Or HostOS="macos")
					MINGW_PATH=path
				Endif
			' Dawlane modified for Mac OS X and Linux. 
			Case "MINGW_TOOLCHAIN"
				If Not MINGW_TOOLCHAIN And (HostOS="linux" Or HostOS="macos")
					MINGW_TOOLCHAIN=path
				Endif
			Case "PSM_PATH"
				If Not PSM_PATH And FileType( path )=FILETYPE_DIR
					PSM_PATH=path
				Endif
			Case "MSBUILD_PATH"
				If Not MSBUILD_PATH And FileType( path )=FILETYPE_FILE
					MSBUILD_PATH=path
				Endif
			Case "HTML_PLAYER" 
				HTML_PLAYER=rhs
			Case "FLASH_PLAYER" 
				FLASH_PLAYER=rhs
			Default 
				Print "Trans: ignoring unrecognized config var: "+lhs
			End
	
		Next
		
		Select HostOS
		Case "winnt"
			Local path:=GetEnv( "PATH" )
			
			If ANDROID_PATH path+=";"+ANDROID_PATH+"/tools"
			If ANDROID_PATH path+=";"+ANDROID_PATH+"/platform-tools"
			If JDK_PATH path+=";"+JDK_PATH+"/bin"
			If ANT_PATH path+=";"+ANT_PATH+"/bin"
			If FLEX_PATH path+=";"+FLEX_PATH+"/bin"
			
			If MINGW_PATH path=MINGW_PATH+"/bin;"+path	'override existing mingw path if any...
	
			SetEnv "PATH",path
			
			If JDK_PATH SetEnv "JAVA_HOME",JDK_PATH
	
		Case "macos"

			'Execute "echo $PATH"
			'Print GetEnv( "PATH" )
		
			Local path:=GetEnv( "PATH" )
			
			If ANDROID_PATH path+=":"+ANDROID_PATH+"/tools"
			If ANDROID_PATH path+=":"+ANDROID_PATH+"/platform-tools"
			If ANT_PATH path+=":"+ANT_PATH+"/bin"
			If FLEX_PATH path+=":"+FLEX_PATH+"/bin"
			
			' Dawlane modified check every thing is OK to use the cross compiler before adding the paths
			If opt_mingw32cross And MINGW_PATH<>"" And (FileType(MINGW_PATH+"/bin/"+MINGW_TOOLCHAIN+"-g++")=1 Or FileType(MINGW_PATH+"/"+MINGW_TOOLCHAIN+"/bin/"+MINGW_TOOLCHAIN+"-g++")=1)
				path+=":"+MINGW_PATH+"/bin:"+MINGW_PATH+"/include:"+MINGW_PATH+"/lib"
				path+=":"+MINGW_PATH+"/i686-w64-mingw32/bin:"+MINGW_PATH+"/i686-w64-mingw32/include:"+MINGW_PATH+"/i686-w64-mingw32/lib"
				path+=":"+MINGW_PATH+"/x86_64-w64-mingw32/bin:"+MINGW_PATH+"/x86_64-w64-mingw32/include:"+MINGW_PATH+"/x86_64-w64-mingw32/lib"
			Else
				opt_mingw32cross=False ' If the path nor the cross compile flag is set do a standard host build
			Endif
			
			SetEnv "PATH",path
			
			'Execute "echo $PATH"
			'Print GetEnv( "PATH" )
			
		Case "linux"

			Local path:=GetEnv( "PATH" )
			
			If JDK_PATH path=JDK_PATH+"/bin:"+path
			If ANDROID_PATH path=ANDROID_PATH+"/platform-tools:"+path
			If FLEX_PATH path=FLEX_PATH+"/bin:"+path
			
			' Dawlane modified check every thing is OK to use the cross compiler
 			If opt_mingw32cross
 				If MINGW_TOOLCHAIN="" Or (FileType("/usr/bin/"+MINGW_TOOLCHAIN+"-gcc") <>1 Or FileType("/usr/bin/"+MINGW_TOOLCHAIN+"-g++") <>1) Then opt_mingw32cross=False
 			Endif
			SetEnv "PATH",path
			
		End
		
	End
	
	Method Execute:Bool( cmd:String,failHard:Bool=True )
	'	Print "Execute: "+cmd
		Local r:=os.Execute( cmd )
		If Not r Return True
		If failHard Die "Error executing '"+cmd+"', return code="+r
		Return False
	End

End
