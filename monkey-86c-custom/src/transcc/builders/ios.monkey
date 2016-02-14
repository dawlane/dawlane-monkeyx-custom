Import builder

#Rem
	Dawlane modifications
	Removed code that worked on versions of Xcode prior to Xcode 6
	Uses new Execute function to get output from child process. This allows getting information from the tools and should cut out a lot of nasty hacks.
	Use Xcode, instruments
#End
Class IosBuilder Extends Builder
	
	Field _nextFileId:=0
	
	Field _fileRefs:=New StringMap<String>
	Field _buildFiles:=New StringMap<String>

	Field _xcodeVersion:Int[]	' Dawlane
	Field _iOS_SDKVersion:Int[]	' Dawlane

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
		Case "macos"
			Return True
		End
		Return False
	End

	Method Begin:Void()
		ENV_LANG="cpp"
		_trans=New CppTranslator
	End
	
	Method FileId:String( path:String,map:StringMap<String> )
	
		Local id:=map.Get( path )
		If id Return id
		_nextFileId+=1
		id="1ACECAFEBABE"+("0000000000000000"+String(_nextFileId))[-12..]
		map.Set path,id
		Return id
	End

	Method BuildFiles:String()
	
		Local buf:=New StringStack
		For Local it:=Eachin _buildFiles
			Local path:=it.Key
			Local id:=it.Value
			Local fileRef:=FileId( path,_fileRefs )
			Local dir:=ExtractDir( path )
			Local name:=StripDir( path )
			Select ExtractExt( name )
			Case "a","framework"
				buf.Push "~t~t"+id+" = {isa = PBXBuildFile; fileRef = "+fileRef+"; };"
			End
		Next
		If buf.Length buf.Push ""
		Return buf.Join( "~n" )
	End
	
	Method FileRefs:String()
	
		Local buf:=New StringStack
		For Local it:=Eachin _fileRefs
			Local path:=it.Key
			Local id:=it.Value
			Local dir:=ExtractDir( path )
			Local name:=StripDir( path )
			Select ExtractExt( name )
			Case "a"
				buf.Push "~t~t"+id+" = {isa = PBXFileReference; lastKnownFileType = archive.ar; path = ~q"+name+"~q; sourceTree = ~q<group>~q; };"
			Case "h"				
				buf.Push "~t~t"+id+" = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = "+name+"; sourceTree = ~q<group>~q; };"
			Case "framework"
				If dir Die "System frameworks only supported"
				buf.Push "~t~t"+id+" = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = "+name+"; path = System/Library/Frameworks/"+name+"; sourceTree = SDKROOT; };"
			End				
		Next
		If buf.Length buf.Push ""
		Return buf.Join( "~n" )
	End
	
	Method FrameworksBuildPhase:String()
	
		Local buf:=New StringStack
		For Local it:=Eachin _buildFiles
			Local path:=it.Key
			Local id:=it.Value
			Select ExtractExt( path )
			Case "a","framework"
				buf.Push "~t~t~t~t"+id
			End
		Next
		If buf.Length buf.Push ""
		Return buf.Join( ",~n" )
	End
	
	Method FrameworksGroup:String()
	
		Local buf:=New StringStack
		For Local it:=Eachin _fileRefs
			Local path:=it.Key
			Local id:=it.Value
			Select ExtractExt( path )
			Case "framework"
				buf.Push "~t~t~t~t"+id
			End
		Next
		If buf.Length buf.Push ""
		Return buf.Join( ",~n" )
	end
	
	Method LibsGroup:String()
	
		Local buf:=New StringStack
		For Local it:=Eachin _fileRefs
			Local path:=it.Key
			Local id:=it.Value
			Select ExtractExt( path )
			Case "a","h"
				buf.Push "~t~t~t~t"+id
			End
		Next
		If buf.Length buf.Push ""
		Return buf.Join( ",~n" )
	End
	
	Method AddBuildFile:Void( path:String )
	
		FileId path,_buildFiles
	End
	
	Method FindEol:Int( str:String,substr:String,start:Int=0 )
	
		Local i:=str.Find( substr,start )
		If i=-1
			Print "Can't find "+substr
			Return -1
		Endif
		i+=substr.Length
		Local eol:=str.Find( "~n",i )+1
		If eol=0 Return str.Length
		Return eol
	End
	
	Method MungProj:String( proj:String )
	
		Local i:=-1
		
		i=FindEol( proj,"/* Begin PBXBuildFile section */" )
		If i=-1 Return ""
		proj=proj[..i]+BuildFiles()+proj[i..]
		
		i=FindEol( proj,"/* Begin PBXFileReference section */" )
		If i=-1 Return ""
		proj=proj[..i]+FileRefs()+proj[i..]
		
		i=FindEol( proj,"/* Begin PBXFrameworksBuildPhase section */" )
		If i<>-1 i=FindEol( proj,"/* Frameworks */ = {",i )
		If i<>-1 i=FindEol( proj,"files = (",i )
		If i=-1 Return ""
		proj=proj[..i]+FrameworksBuildPhase()+proj[i..]
		
		i=FindEol( proj,"/* Begin PBXGroup section */" )
		If i<>-1 i=FindEol( proj,"/* Frameworks */ = {",i )
		If i<>-1 i=FindEol( proj,"children = (",i )
		If i=-1 Return ""
		proj=proj[..i]+FrameworksGroup()+proj[i..]
		
		
		
		i=FindEol( proj,"/* Begin PBXGroup section */" )
		If i<>-1 i=FindEol( proj,"/* libs */ = {",i )
		If i<>-1 i=FindEol( proj,"children = (",i )
		If i=-1 Return ""
		proj=proj[..i]+LibsGroup()+proj[i..]
		
		Return proj
		
	End
	
	Method Backup:Void( path:String )
	
		Local path2:=path+"_"
		If FileType( path2 )
			CopyFile path2,path
		Else
			CopyFile path,path2
		Endif
	End
	
	Method MungProj:Void()
	
		Local path:="MonkeyGame.xcodeproj/project.pbxproj"
		
		Local proj:=LoadString( path )
		
		'Ok, this ain't pretty...
		Local buf:=New StringStack
		For Local line:=Eachin proj.Split( "~n" )
			If Not line.Trim().StartsWith( "1ACECAFEBABE" ) buf.Push line
		Next
		proj=buf.Join( "~n" )
		
'		Backup path
'		Local proj:=LoadString( path )
		
		proj=MungProj( proj )
		If Not proj Die "Failed to mung XCode project file"
		
		SaveString proj,path
		
	End
	
	Method MakeTarget:Void()
	
		CreateDataDir "data"

		Local main:=LoadString( "main.mm" )
		
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )
		
		SaveString main,"main.mm"
		
		'mung xcode project
		Local libs:=GetConfigVar( "LIBS" )
		If libs
			For Local lib:=Eachin libs.Split( ";" )
				If Not lib Continue
				Select ExtractExt( lib )
				Case "a","h"
					Local path:="libs/"+StripDir( lib )
					CopyFile lib,path
					AddBuildFile path
				Case "framework"
					AddBuildFile lib
				Default
					Die "Unrecognized lib file type:"+lib
				End
			Next
		Endif
		MungProj
		
		If Not tcc.opt_build Return

#rem
	As far as I can tell there isn't much diference between Xcode 6 and Xcode 7 other than Xcode 7
	no longer having to have a paid subscription for development and clang object linking. You still need to sign up for it and pay for certain services.
#end
		' The variable _xcodeVersion is an array holding the Major, Minor and Revision version of Xcode. This should make it a lot easier to build for a version of xcodebuild	
		_xcodeVersion=XCODEVersion()
		Print "**** XCODE "+Version2String( _xcodeVersion )+" detected ****"
	
		' Set a few variables
		' The variable useDevice should hold a non zero if the device is to be the destination and not the simulator
		' 
		Local cmdStr:String="", UDID:String, iOS_Device:String, useDevice:=GetConfigVar( "IOS_USE_DEVICE" )
		Local bundleID:String, productID:String, lastBundleID:String, lastProductID:String
		
		' Check that xcrun tool is installed. This tool was introduced in Xcode tools 5
		If Not XCRUNCheck() Die "**** xcrun is not installed. Check that Xcode tools are set up ****"
		
		' Should be posible to use other SDK's than the default. Just make sure that they are install in the Xcode bundle in the correct location e.g. xcode.app/
		If GetConfigVar( "IOS_SDK_VERSION" )<>"" _iOS_SDKVersion=Version2Array( GetConfigVar( "IOS_SDK_VERSION" ) ) Else GetSDKVersion()	
		
		' If the device is known and set then use it. Else use the standard iPhone 4s. May move this to a setting in config.macos.txt to make it easier to update
		iOS_Device=GetConfigVar( "IOS_DEVICE_NAME" )
		If Not iOS_Device iOS_Device="iPhone 4s"
		
		UDID=XCODEGetDeviceUDID( iOS_Device, _iOS_SDKVersion )
		If Not UDID Die "**** Error: Unable to find "+iOS_Device+" with iOS SDK version "+Version2String( _iOS_SDKVersion, True )+" ****"
		
		' Xcode 6/7 allows you to change the bundle identifier via the xcodebuild, but the original xcode project file must be updated first to use it
		bundleID=GetConfigVar( "IOS_BUNDLE_ID" )
		productID=GetConfigVar( "IOS_PRODUCT_ID" )
		
		' If no bundle or product id is supplied then use the defaults
		If Not bundleID bundleID="com.yourcompany"
		If Not productID productID="MonkeyGame"
		bundleID=String(bundleID+"."+productID).Replace( " ", "-" ) 	' Make sure that our budle id will match with the product name
		
		' Dawlane modified Last build status storage
		If FileType( "buildfile" )=FILETYPE_FILE
			BuildStatus.LoadFile()
			lastProductID=BuildStatus.GetKey( casedConfig+"_productID" )
			lastBundleID=BuildStatus.GetKey( casedConfig+"_bundleID" )
			Print "**** Last iOS App File Product name was "+lastProductID+" ****"
			Print "**** Last iOS App File Bundle identifier was "+lastBundleID+" ****"
		Endif
		
		' Revome old build file and update
		If lastProductID.Compare( productID ) Or lastBundleID.Compare( bundleID ) If FileType( "Build" )=FILETYPE_DIR DeleteDir( "Build", True )
		BuildStatus.AddKey( casedConfig+"_productID", productID )
		BuildStatus.AddKey( casedConfig+"_bundleID", bundleID )
		BuildStatus.SaveFile()
		
		' Build command for simulator
		If Not useDevice
			cmdStr="-configuration "+casedConfig+" -sdk iphonesimulator"+Version2String( _iOS_SDKVersion )+" -destination 'platform=iOS Simulator,id="+UDID+"'"
			cmdStr+=" -derivedDataPath ./ -scheme MonkeyGame clean build"
			cmdStr+=" PRODUCT_BUNDLE_IDENTIFIER=~q"+bundleID+"~q PRODUCT_NAME=~q"+productID+"~q"
			Execute "xcodebuild "+cmdStr
		Else
			cmdStr="-configuration "+casedConfig+" -sdk iphoneos"+Version2String( _iOS_SDKVersion )+" -destination 'platform=iOS,id="+UDID+"'"
			cmdStr+=" -derivedDataPath ./ -scheme MonkeyGame build"
			cmdStr+=" PRODUCT_BUNDLE_IDENTIFIER=~q"+bundleID+"~q PRODUCT_NAME=~q"+productID+"~q"
			If _xcodeVersion[0]=7 cmdStr+=" CLANG_LINK_OBJC_RUNTIME=OFF"			
			If GetConfigVar( "IOS_XCODE_OPTS" ) cmdStr+=" "+GetConfigVar( "IOS_XCODE_OPTS" )
			Execute "xcodebuild "+cmdStr
			cmdStr="PRODUCT_BUNDLE_IDENTIFIER=~q"+bundleID+"~q PRODUCT_NAME=~q"+productID+"~q archive -scheme MonkeyGame -archivePath ~q"+RealPath( "./Build/Products/"+casedConfig+"-iphoneos" )+"/"+productID+".xcarchive~q"
			Execute "xcodebuild "+cmdStr
			cmdStr="-exportArchive -archivePath ~q"+RealPath( "./Build/Products/"+casedConfig+"-iphoneos" )+"/"+productID+".xcarchive~q"
			cmdStr+=" -exportPath ~q"+RealPath( "./Build/Products/"+casedConfig+"-iphoneos" )+"/"+productID+"~q -exportFormat ipa -exportWithOriginalSigningIdentity"
			Execute "xcodebuild "+cmdStr
			' Create ipa
			'cmdStr="xcrun -sdk iphoneos"+Version2String( _iOS_SDKVersion )+" PackageApplication -v ~q"+RealPath( "./Build/Products/"+casedConfig+"-iphoneos" )+"/"+productID+".app~q"
			'cmdStr+=" -o ~q"+RealPath( "./Build/Products/"+casedConfig+"-iphoneos" )+"/"+productID+".ipa~q"
			'If GetConfigVar( "IOS_DEV_SIGN_ID" ) cmdStr+=" --sign ~qiPhone Developer: "+GetConfigVar( "IOS_DEV_SIGN_ID" )+"~q"
			'Execute cmdStr
		Endif
		
		If Not tcc.opt_run Return
		
		If Not useDevice
			' Start Simulator
			Local err:=iOSStartSimulator( UDID, productID, bundleID, lastBundleID )
			Select err
				Case 1
					Die "**** Error: There was a problem when executing instruments to start the simulator ****" 
				Case 2
					Die "**** Error: There was a problem when removing the App bundle from the simulator ****"
				Case 3
					Die "**** Error: There was a problem when installing the App bundle to the simulator ****"
				Case 4
					Die "**** Error: There was a problem when launching the App bundle in the simulator ****"
			End Select
		Else
		Endif		
	End

#Rem Dawlane Modified
	iOSStartSimulator: Start iPhone Simulator
	iOSSimBooted: Simulator boot check
	GetSDKVersion: Get the default current iOS SDK
#End
	Method iOSStartSimulator:Int( udid:String, product:String, bundle:String, previousBundle:String="")
		Local str:String, err:Int=-1, lastBundle:String
		' Start the Simulator. The simctl was introduced in xcode 6
		' Use instruments to start the simulator, but give it a blank profiling template and terminate it after 1 millisecond
		' instruments has to be use as simctl boot appears to be broken
		If FileType( "tracefiles.trace" )=FILETYPE_DIR DeleteDir( "tracefiles.trace", True ) ' Clean up instruments trace file
		If Not iOSSimBooted( udid )
			Print "**** Starting Simulator ****"
			err=additional.Execute( "xcrun instruments -w ~q"+udid+"~q -t ~qBlank~q -l ~q1~q -D ~qtracefiles~q", str )
			If err<>0
				Print str
				Return 1
			Endif
		Endif

		Print "**** Checking for previous install ****"
		' iOS apps are identified by their bundle id and not their product name
		If Not previousBundle lastBundle=bundle Else lastBundle=previousBundle
		str=""
		err=additional.Execute( "xcrun simctl get_app_container "+udid+" "+lastBundle, str )
		If err=0 ' An error usually means that the app container doesn't exist so don't try to uninstall
			Print "**** Uninstalling App ****"
			str=""
			err=additional.Execute( "xcrun simctl uninstall "+udid+" "+lastBundle, str )
			If err<>0
				Print str
				Return 2
			Endif
		Endif		
	
		Print "**** Installing App ****"
		str=""
		err=additional.Execute( "xcrun simctl install "+udid+" ~qBuild/Products/"+casedConfig+"-iphonesimulator/"+product+".app~q", str )
		If err<>0
			Print str
			Return 3
		Endif
	
		Print "**** Ready and waiting to execute App ****"
		str=""
		err=additional.Execute( "xcrun simctl launch "+udid+" "+bundle, str )
		If err<>0
			Print str
			err=4
		Else
			err=0
		Endif
		If FileType( "tracefiles.trace" )=FILETYPE_DIR DeleteDir( "tracefiles.trace", True ) ' Clean up instruments trace file
		Return err
	End
		
	Method iOSSimBooted:Bool( udid:String, time:Int=20 )
		Local timeOut:Int, i:Int, str:String
		Print "**** iOS Simulator Booted check ****"
		While timeOut < time
		str=""
		If additional.Execute( "xcrun simctl list | grep "+udid, str )<>0
			Print str
			Die "**** Error: Unable to get the Simulated devices ****"
		Endif
		If str.Contains( "(Booted)" ) Return True
		timeOut+=1
		Wend
		Print "**** iOS Simulator Boot check timed out ****"
		Return False
	End
	
	Method GetSDKVersion:Void()
		Local str:String
		Local err:Int
		err=additional.Execute("xcrun -sdk iphoneos --show-sdk-version", str)
		If err=0 _iOS_SDKVersion=Version2Array( str[ .. str.Find( "~n" ) ] ) Else Die "**** Error: Unable to determine iOS SDK ****"
	End
End

