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
#ifndef COMMAND_H
#define COMMAND_H

#include "marshal.h"

#include "erl_interface.h"
#include "ei.h"

class command
{
private:
	static bool change_log_flag(ETERM *);
	static bool get_session(ETERM *);
	static bool release_conn(ETERM *);
	static bool commit(ETERM *);
	static bool rollback(ETERM *);
	static bool describe(ETERM *);
	static bool prep_sql(ETERM *);
	static bool bind_args(ETERM *);
	static bool exec_stmt(ETERM *);
	static bool fetch_rows(ETERM *);
	static bool close_stmt(ETERM *);
	static bool echo(ETERM *);

public:
	static bool process(void *);
};

// Externs
extern bool cmd_processor(void *);

#endif // COMMAND_H