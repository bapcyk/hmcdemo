#ifndef __MYM_H
#define __MYM_H

#define G 9.80665
#define DEG2RAD(D) ((D)*0.01745329251994329576)

/* threshold for renormalisation of quaternion */
#define RENORMCOUNT 97

// 3-component vector
typedef struct v3_t {
        double v[3]; // values of 3 axis of accelerometer
} v3_t;

/*typedef struct Quat {
        double v[4]; // values
        double rotmx[17]; // rotation matrix (result)
        //double rotmx[4][4]; // rotation matrix (result)
        int count; // for renormalization (threshold)
} Quat;*/

typedef enum Axis {
        /* HACK: bcz dist[0] in CCIntr is len of dist (3) */
        Ox=1,
        Oy,
        Oz
} Axis;

// Low-pass filter
typedef struct CLPFilter {
        int n; // length of v
        double a; // alpha
        double *v; // calculated values (keep prev. before filter)
} CLPFilter;

// High-pass filter
typedef struct CHPFilter {
        int n; // length of v
        double a; // alpha
        double *v; // calculated values (keep prev. before filter)
        double *x; // prev. input
} CHPFilter;

// Composite/Complementary integrator
typedef struct CCIntr {
        double a, b; // alpha, beta
        double dist[4]; // distance/position (keeps prev. before estimate)
} CCIntr;

// Convertor from raw to physical sensor values
typedef struct CPhysValues {
        double v[11]; // 1st - size of array
        int corrg; // correct gravity
} CPhysValues;

// Anti-turning of tilt-angles (occurs due to bias error on scale board +
// filtering)
typedef struct CAntiTurn {
        v3_t tilt;
} CAntiTurn;


typedef double fir_h_t; // XXX only for getter typemap

// Low-pass FIR
typedef struct Clpfir {
        int ord; // number of coefficients (order)
        fir_h_t *h; // coefficientes (not for cget!)
        double *z; // delayed inputs (not for cget!)
        double fs; // read-only: sampling freq
        double f1; // read-only: cut freq
        int win; // read-only: window function is used
        int norm; // read-only: normalization of H is used
        int s; // state (or step?)
} Clpfir;

// High-pass FIR
typedef struct Chpfir {
        int ord; // number of coefficients (order)
        fir_h_t *h; // coefficientes (not for cget!)
        double *z; // delayed inputs (not for cget!)
        double fs; // read-only: sampling freq
        double f1; // read-only: cut freq
        int win; // read-only: window function is used
        int norm; // read-only: normalization of H is used
        int s; // state (or step?)
} Chpfir;

// Band-pass FIR
typedef struct Cbpfir {
        int ord; // number of coefficients (order)
        fir_h_t *h; // coefficientes (not for cget!)
        double *z; // delayed inputs (not for cget!)
        double fs; // read-only: sampling freq
        double f1; // read-only: cut freq 1
        double f2; // read-only: cut freq 2
        int win; // read-only: window function is used
        int norm; // read-only: normalization of H is used
        int s; // state (or step?)
} Cbpfir;

// Simpsone's rule integrator
typedef struct CSIntr {
        double I; // last value of integral
        double y_1; // y[-1]
        double y_2; // y[-2]
        double h; // step of subinterval
        double h_d; // step of subinterval/6
        long long i; // iteration
} CSIntr;


#endif
