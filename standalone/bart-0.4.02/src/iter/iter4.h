/* Copyright 2017. Martin Uecker.
 * All rights reserved. Use of this source code is governed by
 * a BSD-style license which can be found in the LICENSE file.
 */

#include "misc/types.h"

struct iter3_conf_s;
struct iter_op_s;
struct nlop_s;

typedef void iter4_fun_f(iter3_conf* _conf,
		struct nlop_s* nlop,
		long N, float* dst, const float* ref,
		long M, const float* src);

iter4_fun_f iter4_irgnm;
iter4_fun_f iter4_landweber;


extern const struct iter3_irgnm_conf iter3_irgnm_defaults;
// extern const struct iter3_landweber_conf iter3_landweber_defaults;

