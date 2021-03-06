/* Copyright 2012 K2Informatics GmbH, Root Laengenbold, Switzerland
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include "platform.h"
#include "logger.h"

#include "port.h"
#include "cmd_queue.h"
#include "transcoder.h"
#include "threads.h"
#include "marshal.h"

bool log_flag;

int main(int argc, char * argv[])
{
    const char *nls_lang;
    nls_lang = getenv("NLS_LANG");
#ifdef __WIN32__
    _setmode( _fileno( stdout ), _O_BINARY );
    _setmode( _fileno( stdin  ), _O_BINARY );
	DWORD pid = GetCurrentProcessId();
#else
	pid_t pid = getpid();
#endif

	transcoder::instance();
#if 0
		unsigned char b[] = {
			// 131,106 // term_to_binary(""). term_to_binary([]).
			// 131,104,0 //term_to_binary({}).
			131,109,0,0,0,0 // term_to_binary(<<>>).
		};
		vector<unsigned char> buf(b, b + sizeof(b) / sizeof(b[0]));
		term t;
		transcoder::instance().decode(buf, t);
		vector<unsigned char> buf1 = transcoder::instance().encode(t);
		term t1;
		t1.integer((unsigned long long)0xFFFFFFFFFFFFFFFF);
		vector<unsigned char> buf2 = transcoder::instance().encode(t1);
#endif

    log_flag = false;

	// Max term byte size
	if (argc >= 2) {
		max_term_byte_size = atol(argv[1]);
	}

	// Enable Logging
    if (argc >= 3) {
        if (strcmp(argv[2], "true") == 0)
			log_flag = true;
    }

	// Log listner port
	int log_tcp_port = 0;
	if (argc >= 4) {
		log_tcp_port = atol(argv[3]);
		const char * ret = logger::init(log_tcp_port);
		if(ret != NULL) {
			return -1;
		}
	}

    if(nls_lang == NULL)
        nls_lang = "";
	REMOTE_LOG(
        INF,
		"[%lu] Port process configs : erlang term max size 0x%08X bytes, logging %s, TCP port for logs %d,"
        " NLS_LANG %s", pid,
        max_term_byte_size, (log_flag ? "enabled" : "disabled"), log_tcp_port, nls_lang);
	threads::init();
	port& prt = port::instance();
	vector<unsigned char> read_buf;

	while(prt.read_cmd(read_buf) > 0) {
		cmd_queue::push(read_buf);
#ifndef USING_THREAD_POOL
		threads::start();
#endif
    }
	threads::run_threads = false;

	REMOTE_LOG(DBG, "[%lu] terminating...", pid);
#ifdef __WIN32__
	HANDLE hnd;
    hnd = OpenProcess(SYNCHRONIZE | PROCESS_TERMINATE, TRUE, pid);
    TerminateProcess(hnd, 0);
#endif
    // No special exit treatment required for NIX*
    return 0;
}
