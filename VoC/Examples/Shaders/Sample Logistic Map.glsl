#version 420

// original https://www.shadertoy.com/view/lds3Wf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TOTAL_ITER 8        // total iterations for each run thru the map
#define SKIP_ITER 4        // number of iterations to skip to reach the limit cycle
#define N_RUNS 20.0        // number of runs thru logistic map to go thru
#define R_MIN 2.5        // minimum r-value (x axis)
#define R_MAX 4.1        // maximum r-value (x axis)
#define ACCURACY 1000.0        // degree to which we accept limit cycle hits

// might as well use the logistic sigmoid...
float sigmoid(float x, float mid, float slope)
{
    return 1.0 / (1.0 + exp(slope * (x - mid)));
}

void main(void)
{
    // get our pixel coord in [0, 1] (r is x, v is y)
    float r_frac = gl_FragCoord.x / resolution.x;
    float v = gl_FragCoord.y / resolution.y;
    
    // shift r-axis to desired range
    float r = (R_MAX - R_MIN) * r_frac + R_MIN;
    
    // counts how many times our point is in the limit cycle
    float score = 0.0;
    
    // some sinusoids to mess with the map over time
    float s = 0.021 * sin(time / 2.16);
    float c = 0.008 * sin(time / 0.64);
    
    // try different starting values
    for(float x_i = 0.05; x_i < 0.95; x_i += 0.9 / N_RUNS) {
        // iterate the logistic map using our r value!
        float x = x_i;
        for(int a = 0; a < TOTAL_ITER; a++) {
            x = r * (x + s) * (1.0 - x + c);
            
            // measure how close our point is to the target pixel
            if(a >= SKIP_ITER)
                score += exp(-ACCURACY * (1.0 - r_frac / 1.5) * abs(x - v));
        }
    }
    
    // normalize count and turn it into color
    float strength = sigmoid(score / N_RUNS, 0.065 - 0.05 * r_frac, 150.0);
    glFragColor = vec4(strength, strength, strength, 1.0);
}
