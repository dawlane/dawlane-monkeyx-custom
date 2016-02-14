// Windows, Linux, OSX dirty conversion from multi-byte to wchar
String MBTOWC(const char* ptr, size_t bytes){
	String result;
	int len;
	wchar_t dest;
	mbtowc (NULL, NULL, 0);
	while (bytes>0) {
		len = mbtowc(&dest,ptr,bytes);
		if (len<1) break;
		result+=String(dest,1);
		ptr+=len;
		bytes-=len;
	}
	return result;
}

/*
	Add the abillity to pipe child process output.
	Note that for MS Windows only console mode applications are supported at this time and hasn't been tested yet
*/
int Execute( String cmd, String &ref ){
	FILE* filestream;
	char streambuffer[4096];
	int exitcode=-1;
	#ifdef __Win32
	filestream=_popen(String(cmd+" 2>&1").ToCString<char>(), "r");
	#else
	filestream=popen(String(cmd+" 2>&1").ToCString<char>(), "r");
	#endif
	if(filestream==NULL ||cmd==""){
		ref=String("Invalid child process.\n");
		#ifdef __Win32
		_pclose(filestream);
		#else
		pclose(filestream);
		#endif
		return exitcode;
		}
	while(fgets(streambuffer,sizeof(streambuffer), filestream) !=NULL){
		ref+=MBTOWC(streambuffer,sizeof(streambuffer));
	}
	#ifdef __Win32
	return _pclose(filestream);
	#else
	return pclose(filestream);
	#endif
}