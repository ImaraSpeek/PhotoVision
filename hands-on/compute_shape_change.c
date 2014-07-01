#include "math.h"
#include "mex.h"


void mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs) {

    /* Initialize some variables */
    double *base_shape, *base_shape_change, *shape, *shape_change, *tri, *x, *y, *alfa, *beta, *new_x, *new_y, *counts;
    double xi, xj, xk, yi, yj, yk, nom;
    int no_triangles, no_points, i, j;
        
    /* Retrieve inputs */
    base_shape        = mxGetPr(prhs[0]);
    base_shape_change = mxGetPr(prhs[1]);
    shape             = mxGetPr(prhs[2]);
    tri               = mxGetPr(prhs[3]);
    no_points         = mxGetN(prhs[0]);
    no_triangles      = mxGetN(prhs[3]);
    
    /* Construct output array */
    plhs[0] = mxCreateDoubleMatrix(1, no_points, mxREAL);
    shape_change = mxGetPr(plhs[0]);
    
    /* Compute points for which to compute warps: s + s0 */
    x = (double*) malloc(no_triangles * 3 * sizeof(double));
    y = (double*) malloc(no_triangles * 3 * sizeof(double));
    for(i = 0; i < no_triangles * 3; i++) {        
        x[i] = base_shape[((int) tri[i] - 1) * 2]     + base_shape_change[((int) tri[i] - 1) * 2];
        y[i] = base_shape[((int) tri[i] - 1) * 2 + 1] + base_shape_change[((int) tri[i] - 1) * 2 + 1];
    }
    
    /* Compute alfa and beta values for s + s0 */
    alfa = (double*) malloc(no_triangles * 3 * sizeof(double));
    beta = (double*) malloc(no_triangles * 3 * sizeof(double));
    for(i = 0; i < no_triangles; i++) {
        
        /* Obtain coordinates of current triangle */
        xi = base_shape[((int) tri[i * 3]     - 1) * 2];
        xj = base_shape[((int) tri[i * 3 + 1] - 1) * 2];
        xk = base_shape[((int) tri[i * 3 + 2] - 1) * 2];
        yi = base_shape[((int) tri[i * 3]     - 1) * 2 + 1];
        yj = base_shape[((int) tri[i * 3 + 1] - 1) * 2 + 1];
        yk = base_shape[((int) tri[i * 3 + 2] - 1) * 2 + 1];
        
        /* Compute the alfa and beta values */
        for(j = 0; j < 3; j++) {
            nom = (xj - xi) * (yk - yi) - (yj - yi) * (xk - xi);
            alfa[i * 3 + j] = ((x[i * 3 + j] - xi) * (yk - yi) - (y[i * 3 + j] - yi) * (xk - xi)) / nom;
            beta[i * 3 + j] = ((y[i * 3 + j] - yi) * (xj - xi) - (x[i * 3 + j] - xi) * (yj - yi)) / nom;
        }
    }
    
    /* Compute warped shape change due to current triangle: delta s */
    new_x = (double*) malloc(no_triangles * 3 * sizeof(double));
    new_y = (double*) malloc(no_triangles * 3 * sizeof(double));
    for(i = 0; i < no_triangles; i++) {
        
        /* Obtain coordinates of current triangle */
        xi = shape[((int) tri[i * 3]     - 1) * 2];
        xj = shape[((int) tri[i * 3 + 1] - 1) * 2];
        xk = shape[((int) tri[i * 3 + 2] - 1) * 2];
        yi = shape[((int) tri[i * 3]     - 1) * 2 + 1];
        yj = shape[((int) tri[i * 3 + 1] - 1) * 2 + 1];
        yk = shape[((int) tri[i * 3 + 2] - 1) * 2 + 1];
        
        /* Compute coordinates */
        for(j = 0; j < 3; j++) {
            new_x[i * 3 + j] = xi + alfa[i * 3 + j] * (xj - xi) + beta[i * 3 + j] * (xk - xi) - shape[((int) tri[i * 3 + j] - 1) * 2];
            new_y[i * 3 + j] = yi + alfa[i * 3 + j] * (yj - yi) + beta[i * 3 + j] * (yk - yi) - shape[((int) tri[i * 3 + j] - 1) * 2 + 1];
        }
    }
    
    /* Sum and average shape changes delta s */
    counts = calloc(no_points, sizeof(double));
    for(i = 0; i < no_triangles * 3; i++) {
        shape_change[((int) tri[i] - 1) * 2]     += new_x[i];
        shape_change[((int) tri[i] - 1) * 2 + 1] += new_y[i];
        counts[((int) tri[i] - 1) * 2]     += 1;
        counts[((int) tri[i] - 1) * 2 + 1] += 1;
    }
    for(i = 0; i < no_points; i++) {
        shape_change[i] = shape_change[i] / counts[i];
    }
    
    /* Free memory */
    free(x);
    free(y);
    free(alfa);
    free(beta);
    free(new_x);
    free(new_y);
    free(counts);
}
