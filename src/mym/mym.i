%module mym

%{
#include "mym.c"

#ifndef SWIG_NoError
#define SWIG_NoError 0
#endif

/* Utilities
   ==========================================================================
 */


/* Convert Tcl_Obj to double* where 1st double is the length of array. n is
required length of list or -1 if no metter */
static int GetDoubleList(Tcl_Interp *interp, Tcl_Obj *obj, double **ret, int n)
{
    int objc, i;
    Tcl_Obj **objv;
    double tmp;
    double *listPtr;

    if (Tcl_ListObjGetElements(interp, obj, &objc, &objv) != TCL_OK) {
        return (SWIG_MemoryError);
    }

    if (n!=-1 && objc!=n) {
        return (SWIG_ValueError);
    }

    /* HACK: 1st item will be number of items!!! */

    listPtr = (double *)malloc((1+objc) * sizeof (double));
    if (!listPtr) {
        return (SWIG_MemoryError);
    }

    listPtr[0] = objc;
    for (i=0; i<objc; i++) {
        if (Tcl_GetDoubleFromObj(interp, objv[i], &tmp) != TCL_OK) {
            free(listPtr);
            return (SWIG_MemoryError);
        } else {
            listPtr[i+1] = tmp;
        }
    }
    *ret = listPtr;
    return (SWIG_NoError);
}

/* Convert Tcl_Obj to v3_t */
static int Getv3(Tcl_Interp *interp, Tcl_Obj *obj, v3_t *ret)
{
    int objc, i;
    Tcl_Obj **objv;
    double tmp;

    if (Tcl_ListObjGetElements(interp, obj, &objc, &objv) != TCL_OK) {
        return (SWIG_MemoryError);
    }

    if (objc!=3) {
        return (SWIG_ValueError);
    }

    for (i=0; i<objc; i++) {
        if (Tcl_GetDoubleFromObj(interp, objv[i], &tmp) != TCL_OK) {
            return (SWIG_MemoryError);
        } else {
            ret->v[i] = tmp;
        }
    }
    return (SWIG_NoError);
}


/* Convert double *v to Tcl list, n is length of v array */
static Tcl_Obj* SetDoubleList(Tcl_Interp *interp, double *v, int n) {
    Tcl_Obj *res;
    int i;

    if (!v) return (NULL);

    if (n <= 0) return NULL;

    res = Tcl_NewListObj(0, NULL);
    for (i=0; i<n; i++) {
        Tcl_ListObjAppendElement(interp, res, Tcl_NewDoubleObj(v[i]));
    }
    return (res);
}

%}

/* Typemaps
   ==========================================================================
 */

%typemap(in) double * (double *tmp) {
    int res;
    if (SWIG_NoError != (res=GetDoubleList(interp, $input, &tmp, -1))) {
        SWIG_Error(res, "can't convert arguments into internal objects");
        SWIG_fail;
    }
    else {
        $1 = tmp;
    }
}

%typemap(in) v3_t (v3_t tmp) {
    int res;
    if (SWIG_NoError != (res=Getv3(interp, $input, &tmp))) {
        SWIG_Error(res, "can't convert arguments into internal objects");
        SWIG_fail;
    }
    else {
        $1 = tmp;
    }
}


%typemap(freearg) double * (double *tmp) {
    if ($1) { 
        free ($1);
    }
}

/* convert fir_h_t to Tcl object.
FIXME: it's memberout only bcz depends on arg1 (see %arg(arg1)) --
arg1 is the pointer to Clpfir|Chpfir.. structs. So NEVER return fir_h_t
from function!!!
*/
%typemap(out) fir_h_t * h {
    Tcl_Obj *res;

    if (NULL == $1) {
        SWIG_Error(SWIG_ValueError, "wrong number of samples");
        SWIG_fail;
    }

    res = SetDoubleList(interp, $1, 2*%arg(arg1)->ord);
    if (!res) {
        SWIG_Error(SWIG_ValueError, "incorrect result");
        SWIG_fail;
    }
    Tcl_SetObjResult(interp, res);
}

%typemap(out) double * {
    Tcl_Obj *res;

    if (NULL == $1) {
        SWIG_Error(SWIG_ValueError, "wrong number of samples");
        SWIG_fail;
    }

    res = SetDoubleList(interp, &$1[1], (int)($1[0]));
    if (!res) {
        SWIG_Error(SWIG_ValueError, "incorrect result");
        SWIG_fail;
    }
    Tcl_SetObjResult(interp, res);
}

%typemap(out) v3_t {
    Tcl_SetObjResult(interp, SetDoubleList(interp, $1.v, 3));
}

%{
#include <math.h>
%}

%include "mym.h"

/* CLPFilter - simple low-pass filter
   ==========================================================================
 */

%extend CLPFilter {
    void setup(double rc, double dt) {
        $self->a = dt/(rc + dt);
    }

    void reset() {
        int i;
        for (i=1; i <= $self->n; i++) {
            $self->v[i] = 0.0;
        }
    }

    CLPFilter(int n, double rc, double dt) {
        CLPFilter *obj;

        if (NULL == (obj=(CLPFilter*) malloc(sizeof (CLPFilter))))
            goto _NO_OBJ;
        if (NULL == (obj->v=(double*) malloc((n+1) * sizeof (double))))
            goto _NO_V;

        obj->v[0] = obj->n = n;
        CLPFilter_reset(obj);
        CLPFilter_setup(obj, rc, dt);

        return (obj);
_NO_V:
        free(obj);
_NO_OBJ:
        return (NULL);
    }

    ~CLPFilter() {
        if ($self->v) free($self->v);
        if ($self) free($self);
    }

    double* filter(double *v) {
        int i;
        int vlen;

        vlen = (int)v[0];
        if (vlen != $self->n) {
            return (NULL);
        }

        for (i=1; i <= vlen; i++) {
            $self->v[i] += $self->a * (v[i] - $self->v[i]);
        }
        return ($self->v);
    }
};

/* CHPFilter - simple high-pass filter
   ==========================================================================
 */

%extend CHPFilter {
    void setup(double rc, double dt) {
        $self->a = rc/(rc + dt); // not like LPFilter!
    }

    void reset() {
        int i;
        for (i=1; i <= $self->n; i++) {
            $self->v[i] = $self->x[i] = 0.0;
        }
    }

    CHPFilter(int n, double rc, double dt) {
        CHPFilter *obj;

        if (NULL == (obj=(CHPFilter*) malloc(sizeof (CHPFilter))))
            goto _NO_OBJ;
        if (NULL == (obj->v=(double*) malloc((n+1) * sizeof (double))))
            goto _NO_V;
        if (NULL == (obj->x=(double*) malloc((n+1) * sizeof (double))))
            goto _NO_X;

        obj->v[0] = obj->x[0] = obj->n = n;
        CHPFilter_reset(obj);
        CHPFilter_setup(obj, rc, dt);

        return (obj);
_NO_X:
        free(obj->v);
_NO_V:
        free(obj);
_NO_OBJ:
        return (NULL);
    }

    ~CHPFilter() {
        if ($self->v) free($self->v);
        if ($self->x) free($self->x);
        if ($self) free($self);
    }

    double* filter(double *v) {
        int i;
        int vlen;

        vlen = (int)v[0];
        if (vlen != $self->n) {
            return (NULL);
        }

        for (i=1; i <= vlen; i++) {
            $self->v[i] = $self->a * ($self->v[i] + v[i] - $self->x[i]);
            $self->x[i] = v[i];
        }
        return ($self->v);
    }
};

/* Composite integrator
   ==========================================================================
 */

%extend CCIntr {
    void setup(double a) {
        $self->a = a;
        $self->b = (1.0 - a);
    }

    void reset() {
        int i;
        for (i=1; i<=3; i++) {
            $self->dist[i]= 0.;
        }
    }

    CCIntr(double a) {
        CCIntr *obj;

        if (NULL == (obj=(CCIntr*) malloc(sizeof (CCIntr))))
            return (NULL);

        obj->dist[0] = 3.;
        CCIntr_reset(obj);
        CCIntr_setup(obj, a);
        return (obj);
    }

    ~CCIntr() {
        free($self);
    }

    /* t should be in msec */
    double* estimate(double dt, double ax, double ay, double az) {
        /* xk = alpha * (xk_1 + A*dt*dt/2) + beta*A */
        $self->dist[Ox] = $self->a * ($self->dist[Ox] + ax * dt * dt / 2.) +
            $self->b * ax;
        $self->dist[Oy] = $self->a * ($self->dist[Oy] + ay * dt * dt / 2.) +
            $self->b * ay;
        $self->dist[Oz] = $self->a * ($self->dist[Oz] + az * dt * dt / 2.) +
            $self->b * az;

        return ($self->dist);
    }
};

/* Convertor to physical values
   ==========================================================================
 */

%extend CPhysValues {
    void setup(int corrg) {
        $self->corrg = corrg;
    }

    void reset() {
        int i;
        $self->v[0] = 10.;
        for (i=1; i<=10; i++) {
            $self->v[i] = 0.;
        }
        $self->corrg = 1;
    }

    CPhysValues() {
        CPhysValues *obj;

        if (NULL == (obj=(CPhysValues*) malloc(sizeof (CPhysValues))))
            return (NULL);

        CPhysValues_reset(obj);
        return (obj);
    }

    ~CPhysValues() {
        free($self);
    }

    double* convert(double *raw) {
        int n = (int)raw[0];

        if (n != 10) {
            return (NULL);
        }

#define head   $self->v[1]
#define pitch  $self->v[2]
#define roll   $self->v[3]
#define ax     $self->v[4]
#define ay     $self->v[5]
#define az     $self->v[6]
#define mx     $self->v[7]
#define my     $self->v[8]
#define mz     $self->v[9]
#define temper $self->v[10]

        head = raw[1]/10.;
        pitch = raw[2]/10.;
        roll = raw[3]/10.;

        ax = raw[4]/8600.;
        ay = raw[5]/8600.;
        az = raw[6]/8600.;

        mx = raw[7]/13000.;
        my = raw[8]/13000.;
        mz = raw[9]/13000.;

        temper = raw[10]/10.;

        if ($self->corrg) {
            double gx, gy, gz, tmp;

            gx = sin(DEG2RAD(pitch));
            gy = sin(DEG2RAD(roll));
            tmp = cos(DEG2RAD(2*pitch)) + cos(DEG2RAD(2*roll));
            gz = 0.70710678118654752440 * sqrt(fabs(tmp));

            ax += gx;
            ay += gy;
            if (fabs(pitch) > 90.0 || fabs(roll) > 90.0) {
                az -= gz;
            }
            else {
                az += gz;
            }
        }

#undef head
#undef pitch
#undef roll
#undef ax
#undef ay
#undef az
#undef mx
#undef my
#undef mz
#undef temper

        return ($self->v);
    }
};

/* Rotation compensator
   ==========================================================================
 */

%extend CAntiTurn {
    void reset() {
        int i;
        for (i=0; i<3; i++) $self->tilt.v[i] = 0.;
    }

    CAntiTurn() {
        CAntiTurn *obj;

        if (NULL == (obj=(CAntiTurn*) malloc(sizeof (CAntiTurn))))
            return (NULL);

        CAntiTurn_reset(obj);
        return (obj);
    }

    ~CAntiTurn() {
        free($self);
    }

/* FIXME pitch range is +-90 -- does these values are valid for such range??
*/
#define V0 $self->tilt.v[i]
#define V1 tilt.v[i]

    v3_t prefilt(v3_t tilt) {
        double abs_d, d;
        int i;
        for (i=0; i<3; i++) {
            abs_d = fabs(V1 - V0);
            if (abs_d > 180.) {
                d = 360. - abs_d;
                if (V0 > V1)
                    V0 += d;
                else
                    V0 -= d;
            }
            else {
                V0 = V1;
            }
        }
        return ($self->tilt);
    }

    v3_t postfilt(v3_t tilt) {
        v3_t res;
        int i;
        for (i=0; i<3; i++) {
            if (fabs(V1) >= 360.) {
                //V0 = fmod(tilt.v[i], 360.);
                res.v[i] = fmod(tilt.v[i], 360.);
            }
            else {
                //V0 = V1;
                res.v[i] = V1;
            }
        }
        return (res);
        //return ($self->tilt);
    }

#undef V0
#undef V1
};

/* Low-pass FIR
   ==========================================================================
 */

%extend Clpfir {
    /* free internal buffers */
    void free_bufs() {
        if ($self->h) {
            free($self->h);
            $self->h = NULL;
        }
        if ($self->z) {
            free($self->z);
            $self->z = NULL;
        }
    }

    /* Order is ord, fs is sampling freq in Hz, f1 is cut-freq,
    win is flag that windowing is need (Blackman window func. is used),
    norm - need normalization (sum of coefficients will be 1) */
    int setup(int ord, double fs, double f1, int win, int norm) {

        double  fc, // cut freq
                ord_1, // ord-1
                d1,
                d2,
                sum,
                h, // impulse fun value
                w; // window fun value
        int i;

        Clpfir_free_bufs($self);

        // h is double-sized: bcz filter() use "double-h" algorithm

        $self->h = (double*) malloc((ord*2) * sizeof (double));
        if (!$self->h) {
            return (1);
        }
        $self->z = (double*) malloc(ord * sizeof (double));
        if (!$self->z) {
            Clpfir_free_bufs($self);
            return (1);
        }

        $self->ord = ord;
        $self->fs = fs;
        $self->f1 = f1;
        $self->win = win;
        $self->norm = norm;
        $self->s = 0;

        fc = M_PI * 2.0 * f1 / fs;
        ord_1 = (double)ord - 1.0;
        d1 = ord_1 / 2.0;

        if (win) {
            // if need window function
            sum = 0.;
            for (i=0; i<ord; i++) {
                d2 = (double)i - d1;
                h = d2==0? fc/M_PI : sin(fc*d2)/(M_PI*d2);
                w = 0.42 - 0.5*cos(2*M_PI*i/ord_1) + 0.08*cos(4*M_PI*i/ord_1);
                h *= w;
                sum += h;
                $self->h[i] = h;
                $self->z[i] = 0.;
            }
        }
        else {
            // without window function
            sum = 0.;
            for (i=0; i<ord; i++) {
                d2 = (double)i - d1;
                h = d2==0? fc/M_PI : sin(fc*d2)/(M_PI*d2);
                sum += h;
                $self->h[i] = h;
                $self->z[i] = 0.;
            }
        }

        if (norm) {
            // normalization of coefficients if need
            for (i=0; i<ord; i++)
                $self->h[i] /= sum;
        }

        // doubling coefficients (C0,C1...Cord-1,C0,C1...Cord-1), count=ord*2
        for (i=0; i<ord; i++)
            $self->h[i + ord] = $self->h[i];

        /*for(i=0; i<2*ord; i++)
            printf("h[%d] = %f\n", i, $self->h[i]);*/

        return (0);
    }

    void reset() {
        int i;
        $self->s = 0;
        for (i=0; i<$self->ord; i++) {
            $self->z[i] = 0.;
        }
    }

    Clpfir(int ord, double fs, double f1, int win, int norm) {
        Clpfir *obj;

        if (NULL == (obj=(Clpfir*) malloc(sizeof (Clpfir))))
            return (NULL);

        obj->h = NULL;
        obj->z = NULL;

        if (Clpfir_setup(obj, ord, fs, f1, win, norm)) {
            free(obj);
            return (NULL);
        }

        Clpfir_reset(obj);
        return (obj);
    }

    ~Clpfir() {
        Clpfir_free_bufs($self);
        if ($self) free($self);
    }

    /* Filter with circular-buffer by "double-h" algorithm */
    double filter(double v) {
        double accum;
        int i;
        double const *p_h, *p_z;

        /* store input at the beginning of the delay line */
        $self->z[$self->s] = v;

        /* calculate the filter */
        p_h = $self->h + $self->ord - $self->s;
        p_z = $self->z;
        accum = 0;
        for (i = 0; i < $self->ord; i++) {
            accum += *p_h++ * *p_z++;
        }

        /* decrement state, wrapping if below zero */
        if (--$self->s < 0) {
            $self->s += $self->ord;
        }

        return (accum);
    }

};

/* High-pass FIR
   ==========================================================================
 */

%extend Chpfir {
    /* free internal buffers */
    void free_bufs() {
        if ($self->h) {
            free($self->h);
            $self->h = NULL;
        }
        if ($self->z) {
            free($self->z);
            $self->z = NULL;
        }
    }

    /* Order is ord, fs is sampling freq in Hz, f1 is cut-freq,
    win is flag that windowing is need (Blackman window func. is used),
    norm - need normalization (sum of coefficients will be 1) */
    int setup(int ord, double fs, double f1, int win, int norm) {

        double  fc, // cut freq
                ord_1, // ord-1
                d1,
                d2,
                sum,
                h, // impulse fun value
                w; // window fun value
        int i;

        Chpfir_free_bufs($self);

        // h is double-sized: bcz filter() use "double-h" algorithm

        $self->h = (double*) malloc((ord*2) * sizeof (double));
        if (!$self->h) {
            return (1);
        }
        $self->z = (double*) malloc(ord * sizeof (double));
        if (!$self->z) {
            Chpfir_free_bufs($self);
            return (1);
        }

        $self->ord = ord;
        $self->fs = fs;
        $self->f1 = f1;
        $self->win = win;
        $self->norm = norm;
        $self->s = 0;

        fc = M_PI * 2.0 * f1 / fs;
        ord_1 = (double)ord - 1.0;
        d1 = ord_1 / 2.0;

        if (win) {
            // if need window function
            sum = 0.;
            for (i=0; i<ord; i++) {
                d2 = (double)i - d1;
                h = d2==0? 1.0 - fc/M_PI : (sin(M_PI*d2) - sin(fc*d2))/(M_PI*d2);
                w = 0.42 - 0.5*cos(2*M_PI*i/ord_1) + 0.08*cos(4*M_PI*i/ord_1);
                h *= w;
                sum += h;
                $self->h[i] = h;
                $self->z[i] = 0.;
            }
        }
        else {
            // without window function
            sum = 0.;
            for (i=0; i<ord; i++) {
                d2 = (double)i - d1;
                h = d2==0? 1.0 - fc/M_PI : (sin(M_PI*d2) - sin(fc*d2))/(M_PI*d2);
                sum += h;
                $self->h[i] = h;
                $self->z[i] = 0.;
            }
        }

        if (norm) {
            // normalization of coefficients if need
            for (i=0; i<ord; i++)
                $self->h[i] /= sum;
        }

        // doubling coefficients (C0,C1...Cord-1,C0,C1...Cord-1), count=ord*2
        for (i=0; i<ord; i++)
            $self->h[i + ord] = $self->h[i];

        /*for(i=0; i<2*ord; i++)
            printf("h[%d] = %f\n", i, $self->h[i]);*/

        return (0);
    }

    void reset() {
        int i;
        $self->s = 0;
        for (i=0; i<$self->ord; i++) {
            $self->z[i] = 0.;
        }
    }

    Chpfir(int ord, double fs, double f1, int win, int norm) {
        Chpfir *obj;

        if (NULL == (obj=(Chpfir*) malloc(sizeof (Chpfir))))
            return (NULL);

        obj->h = NULL;
        obj->z = NULL;

        if (Chpfir_setup(obj, ord, fs, f1, win, norm)) {
            free(obj);
            return (NULL);
        }

        Chpfir_reset(obj);
        return (obj);
    }

    ~Chpfir() {
        Chpfir_free_bufs($self);
        if ($self) free($self);
    }

    /* Filter with circular-buffer by "double-h" algorithm */
    double filter(double v) {
        double accum;
        int i;
        double const *p_h, *p_z;

        /* store input at the beginning of the delay line */
        $self->z[$self->s] = v;

        /* calculate the filter */
        p_h = $self->h + $self->ord - $self->s;
        p_z = $self->z;
        accum = 0;
        for (i = 0; i < $self->ord; i++) {
            accum += *p_h++ * *p_z++;
        }

        /* decrement state, wrapping if below zero */
        if (--$self->s < 0) {
            $self->s += $self->ord;
        }

        return (accum);
    }

};

/* Band-pass FIR
   ==========================================================================
 */

%extend Cbpfir {
    /* free internal buffers */
    void free_bufs() {
        if ($self->h) {
            free($self->h);
            $self->h = NULL;
        }
        if ($self->z) {
            free($self->z);
            $self->z = NULL;
        }
    }

    /* Order is ord, fs is sampling freq in Hz, f1,f2 are cut-freq,
    win is flag that windowing is need (Blackman window func. is used),
    norm - need normalization (sum of coefficients will be 1) */
    int setup(int ord, double fs, double f1, double f2, int win, int norm) {

        double  fc1, fc2, // cut freq
                ord_1, // ord-1
                d1,
                d2,
                sum,
                h, // impulse fun value
                w; // window fun value
        int i;

        Cbpfir_free_bufs($self);

        // h is double-sized: bcz filter() use "double-h" algorithm

        $self->h = (double*) malloc((ord*2) * sizeof (double));
        if (!$self->h) {
            return (1);
        }
        $self->z = (double*) malloc(ord * sizeof (double));
        if (!$self->z) {
            Cbpfir_free_bufs($self);
            return (1);
        }

        $self->ord = ord;
        $self->fs = fs;
        $self->f1 = f1;
        $self->f2 = f2;
        $self->win = win;
        $self->norm = norm;
        $self->s = 0;

        fc1 = M_PI * 2.0 * f1 / fs;
        fc2 = M_PI * 2.0 * f2 / fs;
        ord_1 = (double)ord - 1.0;
        d1 = ord_1 / 2.0;

        if (win) {
            // if need window function
            sum = 0.;
            for (i=0; i<ord; i++) {
                d2 = (double)i - d1;
                h = d2==0? (fc2 - fc1)/M_PI : (sin(fc2*d2) - sin(fc1*d2))/(M_PI*d2);
                w = 0.42 - 0.5*cos(2*M_PI*i/ord_1) + 0.08*cos(4*M_PI*i/ord_1);
                h *= w;
                sum += h;
                $self->h[i] = h;
                $self->z[i] = 0.;
            }
        }
        else {
            // without window function
            sum = 0.;
            for (i=0; i<ord; i++) {
                d2 = (double)i - d1;
                h = d2==0? (fc2 - fc1)/M_PI : (sin(fc2*d2) - sin(fc1*d2))/(M_PI*d2);
                sum += h;
                $self->h[i] = h;
                $self->z[i] = 0.;
            }
        }

        if (norm) {
            // normalization of coefficients if need
            for (i=0; i<ord; i++)
                $self->h[i] /= sum;
        }

        // doubling coefficients (C0,C1...Cord-1,C0,C1...Cord-1), count=ord*2
        for (i=0; i<ord; i++)
            $self->h[i + ord] = $self->h[i];

        /*for(i=0; i<2*ord; i++)
            printf("h[%d] = %f\n", i, $self->h[i]);*/

        return (0);
    }

    void reset() {
        int i;
        $self->s = 0;
        for (i=0; i<$self->ord; i++) {
            $self->z[i] = 0.;
        }
    }

    Cbpfir(int ord, double fs, double f1, double f2, int win, int norm) {
        Cbpfir *obj;

        if (NULL == (obj=(Cbpfir*) malloc(sizeof (Cbpfir))))
            return (NULL);

        obj->h = NULL;
        obj->z = NULL;

        if (Cbpfir_setup(obj, ord, fs, f1, f2, win, norm)) {
            free(obj);
            return (NULL);
        }

        Cbpfir_reset(obj);
        return (obj);
    }

    ~Cbpfir() {
        Cbpfir_free_bufs($self);
        if ($self) free($self);
    }

    /* Filter with circular-buffer by "double-h" algorithm */
    double filter(double v) {
        double accum;
        int i;
        double const *p_h, *p_z;

        /* store input at the beginning of the delay line */
        $self->z[$self->s] = v;

        /* calculate the filter */
        p_h = $self->h + $self->ord - $self->s;
        p_z = $self->z;
        accum = 0;
        for (i = 0; i < $self->ord; i++) {
            accum += *p_h++ * *p_z++;
        }

        /* decrement state, wrapping if below zero */
        if (--$self->s < 0) {
            $self->s += $self->ord;
        }

        return (accum);
    }

};

/* Simpson's integrator
   ==========================================================================
 */

%extend CSIntr {
    // FIXME how is more right to do this?
    void reset() {
        $self->I = 0.;
        $self->y_1 = $self->y_2 = 0.;
        $self->i = 0;
    }

    void setup(double h) {
        $self->h = h;
        $self->h_d = h/3.;
    }

    CSIntr(double h) {
        CSIntr *obj;

        if (NULL == (obj=(CSIntr*) malloc(sizeof (CSIntr))))
            return (NULL);
        CSIntr_reset(obj);
        CSIntr_setup(obj, h);
        return (obj);
    }

    ~CSIntr() {
        if ($self) free($self);
    }

    double calculate(double y) {
        if ($self->i <= 1)
            $self->I = 0;
        else if (0 == $self->i % 2)
            $self->I += $self->h_d * ($self->y_2 + 4. * $self->y_1 + y);

        $self->y_2 = $self->y_1;
        $self->y_1 = y;
        $self->i++;
        return ($self->I);
    }

};
/* Quaternion
   ==========================================================================
 */

/*%extend Quat {
    void reset() {
        int i;

        for (i=0; i<4; i++) {
            $self->v[i] = 0.;
        }

        $self->rotmx[0] = 16.;
        for (i=1; i<=16; i++) {
            $self->rotmx[i] = 0.;
        }
        $self->count = 0;
    }

    Quat() {
        Quat *obj;

        if (NULL == (obj=(Quat*) malloc(sizeof (Quat))))
            return (NULL);

        Quat_reset(obj);
        return (obj);
    }

    ~Quat() {
        free($self);
    }

    void from_axis(double *a, double angle) {
        Quat_reset($self);
        axis_to_quat(a, angle, $self->v);
    }

    void from_euler(double h, double p, double r) {
        Quat_reset($self);
        euler_to_quat(h, p, r, $self->v);
    }

    void add(Quat *q1) {
        add_quats($self->v, q1->v, $self->v, &$self->count);
    }

    double* to_rotmx() {
        build_rotmatrix((double(*)[4])($self->rotmx + 1), $self->v);
        return ($self->rotmx);
    }
};*/
