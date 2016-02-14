
Import builder

Class GlfwBuilder Extends Builder

	Method New( tcc:TransCC )
		Super.New( tcc )
	End
	
	Method Config:String()
		Local config:=New StringStack
		For Local kv:=Eachin GetConfigVars()
			config.Push "#define CFG_"+kv.Key+" "+kv.Value
		Next
		Return config.Join( "~n" )
	End
	
	'***** GCC *****
	' Dawlane modified: If the GLFW_APP_LABEL is used, then make this the output file name as well
	Method MakeGcc:Void(fileOut:String)
	
		' Dawlane modified get any GLFW GCC CC/LD/LIBS config options
		Local cc_opts:=GetConfigVar( "GLFW_GCC_CC_OPTS" )
		Local ld_opts:=GetConfigVar( "GLFW_GCC_LD_OPTS" )
		Local ld_lib_opts:=GetConfigVar( "GLFW_GCC_LDLIBS_OPTS" ) ' Give the option to link addition libraries
		Local msize:=GetConfigVar( "GLFW_DESKTOP_MSIZE" )
		Local dst:String, xcopts:String, choice:Int, lastBuildName:String
		
		' Dawlane modified Mingw32 cross-compiler
		' Choose which target to build for
		If Not tcc.opt_mingw32cross 
			Print "**** Using native MinGW/GCC compiler ****"
			dst="gcc_"+HostOS
		Else
			Print "**** Using MinGW cross compiler ****"
			dst="gcc_winnt"
			' Stuff to pass over to the Makefile to trigger a cross compile
			xcopts="MINGW=~q"+tcc.MINGW_TOOLCHAIN+"~q CROSSCOMPILE=1"
			If HostOS="macos"
				xcopts+=" MACOS=1 MINGW_PATH="+tcc.MINGW_PATH
			Endif
		Endif
		
#rem 
Dawlane modified CPU Architecture/GCC cross compiling (32/64 bit building would be considered cross compiling)
	The idea:
			GLFW_DESKTOP_MSIZE overrides all -m32/64 options in CC and LD including the -msize= parameter to transcc
			Setting both CC and LD to -m32/64 overrides the -msize= parameters to transcc	
			Any of these append either 32 or 64 to the debug/release build and final destination directories			
#end
		choice=GetMSize("-m32","-m64",cc_opts,ld_opts)
		Select choice
			Case -1
				If Not (msize Or tcc.opt_msize)
					Die "**** ERROR: Inconsistant 32/64 detected. Check CC and LD option in your source code ****"
				Endif
				If msize
					Print "**** Warning: Inconsistant 32/64 detected. Check CC and LD option in your source code ****"
					' Clear out any doddgy flags that can stop the build
					cc_opts=cc_opts.Replace( "-m32","" )
					ld_opts=ld_opts.Replace( "-m32","" )
					cc_opts=cc_opts.Replace( "-m64","" )
					ld_opts=ld_opts.Replace( "-m64","" )
				Else
					Print "**** Warning: Inconsistant 32/64 detected. Check CC and LD option in your source code ****"
					Print "**** transcc msize set to "+tcc.opt_msize+". Going a head with that option ****"
					choice=Int(tcc.opt_msize)
				Endif
			Case 0
				Select tcc.opt_msize
					Case "32"
						choice=32
					Case "64"
						choice=64
					Default
						If Not msize Print "**** CPU msize could not be determined. Using GCC/MinGW compiler defaults. ****"
				End Select
			Default
				If Not msize And choice>0 Print "**** 32/64 detected in CC/LD parameters. Overriding transcc msize ****"
		End Select
		' If GLFW_DESKTOP_MSIZE set then ignore the above
		If msize
			Select msize
				Case "32","64"
					Print "**** GLFW_DESKTOP_MSIZE set to "+msize+". Overriding options in CC/LD and transcc ****"
					choice=Int(msize)
				Default
					Print "**** CPU msize could not be determined. Using GCC/MinGW compiler defaults. ****"
			End Select
		Endif
		If choice>0 casedConfig+=choice
		
		CreateDir dst+"/"+casedConfig
		CreateDir dst+"/"+casedConfig+"/internal"
		CreateDir dst+"/"+casedConfig+"/external"
		
		CreateDataDir dst+"/"+casedConfig+"/data"
		
		Local main:=LoadString( "main.cpp" )
		
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )
		
		SaveString main,"main.cpp"
		
		If tcc.opt_build

			ChangeDir dst
			CreateDir "build"
			CreateDir "build/"+casedConfig
			
			' Dawlane modified Last build status storage
			If FileType( "buildfile" )=FILETYPE_FILE
				BuildStatus.LoadFile()
				lastBuildName=BuildStatus.GetKey( casedConfig+"_filename" )
				Print "**** Last GLFW Application File Name "+lastBuildName+" ****"
			Endif
			
			' Dawlane modified revome old files and new keys and save
			If lastBuildName.Compare( fileOut )
				If HostOS="winnt"
					If FileType( casedConfig+"/"+lastBuildName+".exe" )=FILETYPE_FILE DeleteFile( casedConfig+"/"+lastBuildName+".exe" )
				Else
					If FileType( casedConfig+"/"+lastBuildName )=FILETYPE_FILE DeleteFile( casedConfig+"/"+lastBuildName )
				Endif
			Endif
			BuildStatus.AddKey( casedConfig+"_filename", fileOut )
			BuildStatus.SaveFile() ' Save the file and clear the BuildStatus string map
			
			' Dawlane modified GLFW CC/LD/LIBS options
			If choice > 0
				Print "**** Building "+choice+" bit application ****"
				If tcc.opt_msize Or msize
					' Clean up CC and LD.
					' leaving them in shouldn't hurt as the compiler will use the last -m32/64 option it sees, but prints confusing command lines
					cc_opts=cc_opts.Replace( "-m32","" )
					ld_opts=ld_opts.Replace( "-m32","" )
					cc_opts=cc_opts.Replace( "-m64","" )
					ld_opts=ld_opts.Replace( "-m64","" )
					' Use these
					cc_opts+=" -m"+choice
					ld_opts+=" -m"+choice
				Endif
			Endif
			
			Select ENV_CONFIG
			Case "debug"
				cc_opts+=" -O0"
			Case "release"
				cc_opts+=" -O3 -DNDEBUG"
			End

			Local cmd:="make"
			If HostOS="winnt" And FileType( tcc.MINGW_PATH+"/bin/mingw32-make.exe" ) cmd="mingw32-make"
			
			' Dawlane Modified for MinGw Cross-Compiler
			If HostOS="linux" Or HostOS="macos"
				If tcc.opt_mingw32cross Print "Executing MinGW cross compiler" Else Print "Executing native GCC compiler"
				Execute cmd+" CCOPTS=~q"+cc_opts+"~q LDOPTS=~q"+ld_opts+"~q LDLIBOPTS=~q"+ld_lib_opts+"~q "+xcopts+" OUT=~q"+casedConfig+"/"+fileOut+"~q "
				' Rename the executable for Windows
				If tcc.opt_mingw32cross And (HostOS="linux" Or HostOS="macos")
					Print "**** Appending .exe to executable ****"
					Execute "mv ~q"+casedConfig+"/"+fileOut+"~q ~q"+casedConfig+"/"+fileOut+".exe~q"
				Endif
			Else
				' Windows NT MinGW build chain
				Print "**** Executing MinGW compiler ****"
				Execute cmd+" CCOPTS=~q"+cc_opts+"~q LDOPTS=~q"+ld_opts+"~q LDLIBOPTS=~q"+ld_lib_opts+"~q "+xcopts+" OUT=~q"+casedConfig+"/"+fileOut+"~q "	
			Endif
						
			If tcc.opt_run

				ChangeDir casedConfig
				' Dawlane Modified for MinGw Cross-Compiler execute WINE
				If HostOS="winnt"
					Execute "~q./"+fileOut+"~q"
				Elseif HostOS="linux" And tcc.opt_mingw32cross
					If FileType("/usr/bin/wine")
						Print "**** Executing compiled program via WINE ****"
						Execute "wine ~q"+fileOut+".exe~q"
					Else
						Print "Unable to execute cross compiled code. WINE not installed"
					Endif
				Elseif HostOS="macos" And tcc.opt_mingw32cross
					If FileType("/usr/local/bin/wine")
						Print "**** Executing compiled program via WINE ****"
						Execute "/usr/local/bin/wine ~q"+fileOut+".exe~q"
					Else
						Print "**** Unable to execute cross compiled code. WINE not installed ****"
					Endif	
				Else
					Print "**** Executing compiled program ****"
					Execute "~q./"+fileOut+"~q"
				Endif
			Endif
		Endif
			
	End
	
	'***** Vc2010 *****
	Method MakeVc2010:Void(fileOut:String)
		Local msbuild_opts:=GetConfigVar( "GLFW_VSTUDIO_OPTS" ), lastBuildName:String
		
		CreateDir "vc2010/"+casedConfig
		CreateDir "vc2010/"+casedConfig+"/internal"
		CreateDir "vc2010/"+casedConfig+"/external"
		
		CreateDataDir "vc2010/"+casedConfig+"/data"
		
		Local main:=LoadString( "main.cpp" )
		
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )
		
		SaveString main,"main.cpp"
		
		If tcc.opt_build

			ChangeDir "vc2010"
			
			' Dawlane modified Last build status storage
			If FileType( "buildfile" )=FILETYPE_FILE
				BuildStatus.LoadFile()
				lastBuildName=BuildStatus.GetKey( casedConfig+"_filename" )
				Print "**** Last GLFW Application File Name "+lastBuildName+" ****"
			Endif
			
			' Dawlane modified revome old files and new keys and save
			If lastBuildName.Compare( fileOut )
				Local dir:String[]=LoadDir( "build/"+casedConfig )
				For Local line:=Eachin dir
					If line.Contains( ".manifest" ) Or line.Contains( ".tlog" ) Or line.Contains( ".lastbuild" ) DeleteFile( "build/"+casedConfig+"/"+line )
				Next
				If FileType( casedConfig+"/"+lastBuildName+".exe" )=FILETYPE_FILE DeleteFile( casedConfig+"/"+lastBuildName+".exe" )
			Endif
			BuildStatus.AddKey( casedConfig+"_filename", fileOut )
			BuildStatus.SaveFile() ' Save the file and clear the BuildStatus string map

			Execute "~q"+tcc.MSBUILD_PATH+"~q /p:Configuration="+casedConfig+" "+msbuild_opts+" /p:Platform=Win32 /p:projectname=~q"+fileOut+"~q MonkeyGame.sln"
			
			If tcc.opt_run
			
				ChangeDir casedConfig

				Execute "~q"+fileOut+"~q"
				
			Endif
		Endif
	End

	'***** Msvc *****
	Method MakeMsvc:Void(fileOut:String)
				
		' Dawlane modified CPU Architecture	
		' Pass Platform Win32/64 to the VS project file
		' and append either 32 or 64 to the debug/release build and final directories
		Local platform:String, choice:Int, lastBuildName:String
		Local msize:=GetConfigVar( "GLFW_DESKTOP_MSIZE" )
		Local msbuild_opts:=GetConfigVar( "GLFW_VSTUDIO_OPTS" )	' Get exrat options
		If msize tcc.opt_msize=msize 	' Config setting GLFW_DESKTOP_MSIZE overrides transcc option -msize=
		If tcc.opt_msize
			Select tcc.opt_msize
				Case "32"					
					choice=32
					platform="/p:Platform=Win32"
				Case "64"
					choice=64
					platform="/p:Platform=Win64"
				Default
					Print "CPU architecture could not be determined. Using 32 bit solution."
					choice=32
					platform="/p:Platform=Win32"
			End Select
			Print "**** Building "+choice+" bit GLFW binary ****"	
		Endif
		If choice>0 casedConfig+=choice
		
		CreateDir "msvc"+"/"+casedConfig
		CreateDir "msvc/"+casedConfig+"/internal"
		CreateDir "msvc/"+casedConfig+"/external"
		
		CreateDataDir "msvc/"+casedConfig+"/data"
		
		Local main:=LoadString( "main.cpp" )
		
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )
		
		SaveString main,"main.cpp"
		
		If tcc.opt_build
			Local lastbuild:String
			ChangeDir "msvc"
			
			' Dawlane modified Last build status storage
			If FileType( "buildfile" )=FILETYPE_FILE
				BuildStatus.LoadFile()
				lastBuildName=BuildStatus.GetKey( casedConfig+"_filename" )
				Print "**** Last GLFW Application File Name "+lastBuildName+" ****"
			Endif
			
			' Dawlane modified revome old files and new keys and save
			If lastBuildName.Compare( fileOut )
				If FileType( casedConfig+"/"+lastBuildName+".exe" )=FILETYPE_FILE DeleteFile( casedConfig+"/"+lastBuildName+".exe" )
				If FileType( "build/"+casedConfig+"/"+lastBuildName+".tlog" )=FILETYPE_DIR DeleteDir( "build/"+casedConfig+"/"+lastBuildName+".tlog", True )
			Endif
			BuildStatus.AddKey( casedConfig+"_filename", fileOut )
			BuildStatus.SaveFile() ' Save the file and clear the BuildStatus string map
			
			Execute "~q"+tcc.MSBUILD_PATH+"~q /p:Configuration="+casedConfig+" "+platform+" "+msbuild_opts+" /p:projectname=~q"+fileOut+"~q"
			
			If tcc.opt_run
			
				ChangeDir casedConfig

				Execute "~q"+fileOut+"~q"
				
			Endif
		Endif
	End

	'***** Xcode *****	
	Method MakeXcode:Void(fileOut:String)

		CreateDataDir "xcode/data"

		Local main:=LoadString( "main.cpp" ), lastBuildName:String
		Local xcode_opts:=GetConfigVar( "GLFW_XCODE_OPTS" )
		
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )
		
		SaveString main,"main.cpp"
		
		If tcc.opt_build
		
			ChangeDir "xcode"
			
			' Dawlane modified Last build status storage
			If FileType( "buildfile" )=FILETYPE_FILE
				BuildStatus.LoadFile()
				lastBuildName=BuildStatus.GetKey( casedConfig+"_filename" )
				Print "**** Last GLFW Application File Name "+lastBuildName+" ****"
			Endif
			
			' Dawlane modified revome old files and new keys and save
			If lastBuildName.Compare( fileOut ) If FileType( "build" )=FILETYPE_DIR DeleteDir( "build", True )
			BuildStatus.AddKey( casedConfig+"_filename", fileOut )
			BuildStatus.SaveFile() ' Save the file and clear the BuildStatus string map
			
'			Execute "set -o pipefail && xcodebuild -configuration "+casedConfig+" | egrep -A 5 ~q(error|warning):~q"
			Execute "xcodebuild -configuration "+casedConfig+" "+xcode_opts+" PRODUCT_NAME=~q"+fileOut+"~q EXECUTABLE_NAME=~q"+fileOut+"~q"
			
			If tcc.opt_run
			
				ChangeDir "build/"+casedConfig
				ChangeDir fileOut+".app/Contents/MacOS"
				
				Execute "./"+fileOut
			Endif
		Endif
	End
	
	'***** Builder *****	
	Method IsValid:Bool()
		Select HostOS
		Case "winnt"
			If tcc.MINGW_PATH Or tcc.MSBUILD_PATH Return True
		Default
			Return True
		End
		Return False
	End
	
	Method Begin:Void()
		ENV_LANG="cpp"
		_trans=New CppTranslator
	End
	
	Method MakeTarget:Void()
		' If GLFW_APP_LABEL is used, then set the out put file name to the same
		Local monkeyName:=GetConfigVar( "GLFW_APP_FILENAME" )
		If Not monkeyName monkeyName="MonkeyGame"
		Select HostOS
		Case "winnt"
			If GetConfigVar( "GLFW_USE_MINGW" )="1" And tcc.MINGW_PATH
				MakeGcc(monkeyName)
			Else If FileType( "vc2010" )=FILETYPE_DIR
				MakeVc2010(monkeyName)
			Else If FileType( "msvc" )=FILETYPE_DIR
				MakeMsvc(monkeyName)
			Else If tcc.MINGW_PATH
				MakeGcc(monkeyName)
			Endif
		Case "macos"
			' Dawlane Modified for MinGw Cross-Compiler.
			If tcc.opt_mingw32cross  MakeGcc(monkeyName) Else MakeXcode(monkeyName)
		Case "linux"
			MakeGcc(monkeyName)
		End
	End
	
End
