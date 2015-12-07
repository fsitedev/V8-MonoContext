#include "v8monoctx.h"

extern "C" {
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "ppport.h"
}

#undef dNOOP
#define dNOOP extern int __attribute__ ((unused)) Perl___notused

typedef struct monocfg MonoContext;

MODULE = V8::MonoContext		PACKAGE = V8::MonoContext	PREFIX = mono_
PROTOTYPES: ENABLE

MonoContext *
mono_new (...)
	PREINIT:
		SV** run_low_memory_notification	= NULL;
		SV** run_idle_notification_loop		= NULL;
		SV** cmd_args						= NULL;
		SV** watch_templates				= NULL;

		HV * opt_hash;
	INIT:
		if (items == 2) {
			if ((!(SvROK(ST(1))) || (SvTYPE(SvRV(ST(1)))) != SVt_PVHV))
				croak ("Options must be a hash ref");
			opt_hash = (HV *)(SvRV(ST(1)));
			if (opt_hash != NULL) {
				run_low_memory_notification = hv_fetch(opt_hash, "run_low_memory_notification", strlen("run_low_memory_notification"), 0);
				if (run_low_memory_notification != NULL && !SvIOK(*run_low_memory_notification)) croak ("'run_low_memory_notification' value must be an unsigned integer");

				run_idle_notification_loop = hv_fetch(opt_hash, "run_idle_notification_loop", strlen("run_idle_notification_loop"), 0);
				if (run_idle_notification_loop != NULL && !SvIOK(*run_idle_notification_loop)) croak ("'run_idle_notification_loop' value must be an unsigned integer");

				cmd_args = hv_fetch(opt_hash, "cmd_args", strlen("cmd_args"), 0);

				if (cmd_args != NULL && strlen( (char *)SvPV_nolen(*cmd_args) ) > CMD_ARGS_LEN) {
					croak ("Too long v8 cmd_args");
				}

				watch_templates = hv_fetch(opt_hash, "watch_templates", strlen("watch_templates"), 0);
			}
		}
		else if (items > 2) {
			croak ("Only one element can be passed in constructor");
		}
	CODE:
		RETVAL = (MonoContext *) calloc(1, sizeof(MonoContext));

		RETVAL->run_low_memory_notification	= (run_low_memory_notification == NULL ? 0 : SvIV(*run_low_memory_notification));
		RETVAL->run_idle_notification_loop	= (run_idle_notification_loop == NULL ? 0 : SvIV(*run_idle_notification_loop));
		RETVAL->watch_templates				= (watch_templates == NULL ? 0 : 1);

		if (cmd_args != NULL) {
			STRLEN len = strlen("cmd_args");
			strcpy(RETVAL->cmd_args, SvPV(*cmd_args, len));
		}
	OUTPUT:
		RETVAL


MODULE = V8::MonoContext		PACKAGE = MonoContextPtr	PREFIX = mono_


void
mono_DESTROY(ctx)
	MonoContext * ctx
	CODE:
	free( ctx );


HV *
mono_counters(pMono)
	MonoContext * pMono
	PREINIT:
		HV * counters;
	CODE:
		counters = (HV *)sv_2mortal((SV *)newHV());
		hv_store(counters, "request_num", 11, newSVuv(pMono->request_num), 0);
		hv_store(counters, "run_low_memory_notification_time", 32, newSVnv(pMono->run_low_memory_notification_time), 0);
		hv_store(counters, "run_idle_notification_loop_time", 31, newSVnv(pMono->run_idle_notification_loop_time), 0);
		hv_store(counters, "compile_time", 12, newSVnv(pMono->compile_time), 0);
		hv_store(counters, "exec_time", 9, newSVnv(pMono->exec_time), 0);

		RETVAL = counters;
	OUTPUT:
		RETVAL

HV *
mono_heap_stat(pMono)
	MonoContext * pMono
	PREINIT:
		HV * res;
		HeapSt st;
	CODE:
		GetHeapStat(&st);

		res = (HV *)sv_2mortal((SV *)newHV());
		hv_store(res, "total", 5, newSVuv(st.total_heap_size), 0);
		hv_store(res, "limit", 5, newSVuv(st.heap_size_limit), 0);
		hv_store(res, "used", 4, newSVuv(st.used_heap_size), 0);
		hv_store(res, "total_executable", 16, newSVuv(st.total_heap_size_executable), 0);
		hv_store(res, "total_physical", 14, newSVuv(st.total_physical_size), 0);

		RETVAL = res;
	OUTPUT:
		RETVAL



bool
mono_execute_file(pMono, fname, out, ...)
		MonoContext * pMono
		char * fname
		SV * out
	PREINIT:
		HV * opt_hash;
		SV** append_val = NULL;
		SV** json_val = NULL;
	INIT:
		if (!SvROK(out) || SvTYPE(out) >= SVt_PVAV) {
			croak("expected STRING ref");
		}

		if (items == 4) {
			if ((!(SvROK(ST(3))) || (SvTYPE(SvRV(ST(3)))) != SVt_PVHV))
				croak ("Options must be a hash ref");
			opt_hash = (HV *)(SvRV(ST(3)));
			if (opt_hash != NULL) {
				append_val = hv_fetch(opt_hash, "append", strlen("append"), 0);
				if (append_val != NULL && SvROK(*append_val)) croak ("'append' value must be a scalar");

				json_val = hv_fetch(opt_hash, "json", strlen("json"), 0);
				if (json_val != NULL && SvROK(*json_val)) croak ("'json' value must be a scalar");
			}
		}
		else if (items > 4) {
			croak ("Three elements can be passed into function");
		}

	CODE:
		std::string _out;
		std::string _fname(fname);
		std::string _append("");
		std::string _json("{}");

		if (append_val != NULL) {
			_append.assign(SvPV_nolen(*append_val));
		}

		if (json_val != NULL) {
			_json.assign(SvPV_nolen(*json_val));
		}

		bool res = ExecuteFile(pMono, _fname, _append, &_json, &_out);
		std::vector<std::string> _err = GetErrors();

		for (unsigned i=0; i < _err.size(); i++) {
			warn (_err.at(i).c_str());
		}

		if (res) {
			sv_setpvn(SvRV(out), _out.c_str(), _out.length());
		}

		RETVAL = res;
	OUTPUT:
		RETVAL



bool
mono_load_file(pMono, fname)
		MonoContext * pMono
		char* fname
	INIT:

	CODE:
		std::string _fname(fname);

		bool res = LoadFile(pMono, _fname);

		std::vector<std::string> _err = GetErrors();

		for (unsigned i=0; i < _err.size(); i++) {
			warn (_err.at(i).c_str());
		}

		RETVAL = res;
	OUTPUT:
		RETVAL


bool
mono_idle_notification(pMono, ms)
		MonoContext * pMono
		int ms
	INIT:

	CODE:
		bool res = IdleNotification(ms);
		RETVAL = res;
	OUTPUT:
		RETVAL


void
mono_low_memory_notification(pMono)
		MonoContext * pMono

	CODE:
		LowMemoryNotification();

