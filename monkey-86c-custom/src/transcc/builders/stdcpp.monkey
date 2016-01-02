
Import builder

Class StdcppBuilder Extends Builder

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
	
	Method IsValid:Bool()
		Select HostOS
		Case "winnt"
			If tcc.MINGW_PATH Return True
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
	
		Select ENV_CONFIG
		Case "debug" SetConfigVar "DEBUG","1"
		Case "release" SetConfigVar "RELEASE","1"
		Case "profile" SetConfigVar "PROFILE","1"
		End
		
		Local main:=LoadString( "main.cpp" )

		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )

		SaveString main,"main.cpp"
		
		Local out:String
		
		If tcc.opt_build
			If HostOS="linux" Or HostOS="macos"
				If Not tcc.opt_mingw32cross Then
					out="main_"+HostOS
				Else
					out="main_winnt"
				Endif
			Else
				out="main_"+HostOS
			EndIf
			DeleteFile out
			
			Local OPTS:="",LIBS:=""
			
			Select ENV_HOST
			
			' Dawlane modified MinGw cross compiler
			Case "winnt"
				If HostOS="linux" Or HostOS="macos" Then
					If HostOS="linux"
						Print "Building MinGW32 cross Linux Command Line"
						OPTS+=" -Wno-free-nonheap-object -I/usr/"+tcc.MINGW_TOOLCHAIN+"/include -I/usr/local/"+tcc.MINGW_TOOLCHAIN+"/include"
						OPTS+=" -I/usr/"+tcc.MINGW_TOOLCHAIN+"/sys-root/mingw/include -I/usr/"+tcc.MINGW_TOOLCHAIN+"/sys-root/"+tcc.MINGW_TOOLCHAIN+"/include"
						LIBS+=" -L/usr/"+tcc.MINGW_TOOLCHAIN+"/lib -L/usr/local"+tcc.MINGW_PATH+"/lib"
						LIBS+=" -L/usr/"+tcc.MINGW_TOOLCHAIN+"/sys-root/mingw/lib -L/usr/"+tcc.MINGW_TOOLCHAIN+"/sys-root/"+tcc.MINGW_TOOLCHAIN+"/lib"
						LIBS+=" -lwinmm -lws2_32"
					Else
						' Mac OS X
						Print "Building MinGW32 cross Mac OS X Command Line"
						OPTS+=" -Wno-free-nonheap-object -I"+tcc.MINGW_PATH+"/include -I"+tcc.MINGW_PATH+"/i686-w64-mingw32/include -I"+tcc.MINGW_PATH+"/x86_64-w64-mingw32/include"
						LIBS+=" -L"+tcc.MINGW_PATH+"/lib -L"+tcc.MINGW_PATH+"/i686-w64-mingw32/lib -L"+tcc.MINGW_PATH+"/x86_64-w64-mingw32/lib"
						LIBS+=" -lwinmm -lws2_32"
					Endif	
				Else
					Print "Building MINGW native Win NT Command Line"
					OPTS+=" -Wno-free-nonheap-object"
					LIBS+=" -lwinmm -lws2_32"
				Endif 
			Case "macos"
				Print "Building native Mac OS X Command Line"
				OPTS+=" -Wno-parentheses -Wno-dangling-else"
				OPTS+=" -mmacosx-version-min=10.6"
			Case "linux"
				Print "Building native Linux GCC Command Line"
				OPTS+=" -Wno-unused-result"
				LIBS+=" -lpthread"
			End
			
			Select ENV_CONFIG
			Case "debug"
				OPTS+=" -O0"
			Case "release"
				OPTS+=" -O3 -DNDEBUG"
			End
			
			Local cc_opts:=GetConfigVar( "CC_OPTS" )
			If cc_opts OPTS+=" "+cc_opts.Replace( ";"," " )
			
			Local cc_libs:=GetConfigVar( "CC_LIBS" )
			If cc_libs LIBS+=" "+cc_libs.Replace( ";"," " )
			
			' Dawlane modified MinGw cross compiler
			If HostOS="linux" Or HostOS="macos"
				If tcc.opt_mingw32cross Then
					If HostOS="linux"
						Print "Executing Cross Compiler MinGW32 Linux"
						Print "Command line /usr/bin/"+tcc.MINGW_TOOLCHAIN+"-g++"+OPTS+" -o "+out+" main.cpp"+LIBS
						Execute "/usr/bin/"+tcc.MINGW_TOOLCHAIN+"-g++"+OPTS+" -o "+out+" main.cpp"+LIBS
					Else
						Print "Executing Cross Compiler MinGW32 Mac OS X"
						Print "Command line /bin/"+tcc.MINGW_TOOLCHAIN+"-g++"+OPTS+" -o "+out+" main.cpp"+LIBS
						Execute tcc.MINGW_PATH+"/bin/"+tcc.MINGW_TOOLCHAIN+"-g++"+OPTS+" -o "+out+" main.cpp"+LIBS
					Endif
					Print "Appending .exe to output file"
					Execute "mv "+out+" "+out+".exe" 
				Else
					If HostOS="linux" Print "Executing native Linux GCC compiler" Else Print "Executing native Mac OS GCC compiler"
					Print "Command line g++"+OPTS+" -o "+out+" main.cpp"+LIBS
					Execute "g++"+OPTS+" -o "+out+" main.cpp"+LIBS
				Endif
			Else
				Print "Executing native Win NT MinGW32 compiler"
				Print "Command line g++"+OPTS+" -o "+out+" main.cpp"+LIBS
				Execute "g++"+OPTS+" -o "+out+" main.cpp"+LIBS
			EndIf
			
			If tcc.opt_run
				If HostOS="linux" Or HostOS="macos" Then
					If tcc.opt_mingw32cross Then
						Print "Executing Window NT Cross compiled file. Should execute if WINE is configured for auto start."
						Execute "~q"+RealPath( out+".exe" )+"~q"
					Else
						Execute "~q"+RealPath( out )+"~q"
					Endif
				Else
					Execute "~q"+RealPath( out )+"~q"
				EndIf
			Endif
		Endif
	End
	
End

