#version 420

// original https://www.shadertoy.com/view/4s2BDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Number of plane waves
const int K = 5;

// Number of stripes per wave
const int NUM_STRIPES = 7;

const int NUM_FREQUENCIES = 10;

// The main (central) spatial frequency
float MEAN_FREQUENCY = 2.;

// The spread of the spatial frequency envelope
const float SIGMA = 2.;

const float PERIOD = 4.;

const float PI = 4.0 * atan(1.0);

float mean;

float gaussian(float x) {
    x -= mean;
    return exp(-x * x / 2.) / SIGMA;
}

// Adjust the  wavelengths for the current spatial scale
float wavelength(int i, float sc) {
    return pow(2., float(i)) * sc;
}

// Modulate each wavelength by a Gaussian envelope in log
// frequency, centered around aforementioned mean with defined
// standard deviation
float weight(int i, float sc) {
    return gaussian(log(wavelength(i, sc)));
}

// 7-th order smoothstep function:
// https://en.wikipedia.org/wiki/Smoothstep
// https://gist.github.com/kylemcdonald/77f916240756a8cfebef
float superSmooth(float x) {
    float xSquared = x * x;
    return xSquared * xSquared * (x * (x * (x * -20. + 70.) - 84.) + 35.);
}

float quasi(in vec2 uv, float rotation) {
    float scale = pow(0.5, fract(time / PERIOD));

    float weightSum = 0.;
    for (int l = 0; l < NUM_FREQUENCIES; l++) {
        weightSum += weight(l, scale);
    }
    
    // Cartesian coordinates
    vec2 coords = uv * 2. * PI * float(NUM_STRIPES);

    float c = 0.;  // Accumulator
    
    // Iterate over all k plane waves
    for (int t = 0; t < K; t++) {
        float tScaled = ( float(t) / float(K) + rotation ) * PI;
        vec2 omega = vec2(cos(tScaled), sin(tScaled));

        // Compute the phase of the plane wave
        float ph = dot(coords, omega);

        // Take a weighted sum over the different spatial scales
        for (int l = 0; l < NUM_FREQUENCIES; l++) {
            c += cos(ph * wavelength(l, scale)) * weight(l, scale);
        }
    }
    // Convert the summed waves to a [0,1] interval
    // and then convert to color
    return superSmooth((c / (weightSum * float(K)) + 1.) / 2.);

}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.) / resolution.x;
    vec2 dipole = vec2(.2,.0);
    float rot = time/17.;
    MEAN_FREQUENCY = 2.;
    mean = MEAN_FREQUENCY * log(2.);
        
    vec4 col =vec4(.0);
    col.r +=  quasi(uv-dipole,rot)*.8;
    
    MEAN_FREQUENCY *= sqrt(2.);
    mean = MEAN_FREQUENCY * log(2.);
    col.b += quasi(uv+dipole,-rot*sqrt(3./2.));
    
    col.g = (col.r+col.b)/2.;

    glFragColor=col;
}
