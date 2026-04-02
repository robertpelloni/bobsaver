#version 420

// original https://www.shadertoy.com/view/slKSRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Followup to https://www.shadertoy.com/view/NlVSDz

In a first step, parameter values are found such that
the corresponding points on the curve have exactly the distance
curve_width to the ray.

This is done using Newton's method.

Of these, the parameter value which corresponds to
the point nearest to the camera is taken.

In a second step, this parameter value is altered by another iteration
method which finds the point on the curve which is nearest to the ray.
(It finds the local minimal distance, which is why it can't get to the wrong branch of the curve.)

The idea is that the first iteration finds out which branch of the curve is hit first,
and gets a parameter value that is only slightly off from that which we actually want,
which is then found by the second iteration.

I haven't thorougly compared the performance of this method to other methods
(Raymarching with line segments or bezier segments approximation
or directly raymarching with the used distance approximation),
maybe i will do this later on.
*/

const float pi=3.1415925;

const int num_iterations=6;
const int num_start_params=32;

const int marching_steps=10;
const int num_iterations2=3;

const float curve_width_sq=.003;
const float eps=.0001;

const int clelia_fac1=1;
const int clelia_fac2=4;

const float radius=1.;

const float rotation_speed=.5;

//#define SHOW_PARAMETER

const float clelia_fac=float(clelia_fac1)/float(clelia_fac2);
const float clelia_period=float(clelia_fac2)*2.*pi;

float spectral(float x){
        return clamp(abs(mod((x/pi+1.)*4.,8.)-4.)-2.,-.75,.75)*.5/.75+.5;
}

vec3 to_col(float x){
    return vec3(spectral(x),spectral(x+pi/2.),spectral(x-pi));
}

mat2 rot(float t){
    return mat2(cos(t),-sin(t),sin(t),cos(t));
}

vec3 parametric(float t){
    //clelia curve
    t*=clelia_period;
    vec3 p = radius*vec3(cos(t)*cos(clelia_fac*t),cos(t)*sin(clelia_fac*t),sin(t));
    p.yz*=rot(mod(rotation_speed*time,2.*pi));
    return p;
}

vec3 parametric_diff(float t){
    //clelia curve
    t*=clelia_period;
    vec3 p = clelia_period*radius*vec3(-clelia_fac*cos(t)*sin(clelia_fac*t)-sin(t)*cos(clelia_fac*t),
                                       clelia_fac*cos(t)*cos(clelia_fac*t)-sin(t)*sin(clelia_fac*t),
                                       cos(t));

    p.yz*=rot(mod(rotation_speed*time,2.*pi));
    return p;
}

float parametric_normal_iteration3d(float t, vec3 p0){
    vec3 p0_to_p=parametric(t)-p0;
    vec3 tang=parametric_diff(t);

    float l_tang=dot(tang,tang);
    return t-dot(tang,p0_to_p)/l_tang;
}

float ray_to_curve_dis_sq(vec3 ro, vec3 rd, float t0){
    vec3 p0=parametric(t0);
    float s0=dot(p0-ro,rd);
    vec3 p1=ro+s0*rd-p0;
    return dot(p1,p1);
}

float ray_to_curve_dis_sq_diff(vec3 ro, vec3 rd, float t0){
    vec3 p0=parametric(t0);
    vec3 p0_diff=parametric_diff(t0);
    float s0=dot(p0-ro,rd);
    vec3 p1=ro+s0*rd-p0;
    return 2.*dot(p1,dot(p0_diff,rd)*rd-p0_diff);
}

bool parametric_curve_newton_trace(vec3 ro, vec3 rd, out vec3 p0, out vec3 nor, out float t1){

    float t0=0.;
    float d0=1e38;
    t1=1e38;

    for(int i=0;i<num_start_params;i++){
        float t=t0;
        for(int j=0;j<num_iterations;j++){
            t-=(ray_to_curve_dis_sq(ro,rd,t)-curve_width_sq)/ray_to_curve_dis_sq_diff(ro,rd,t);
        }
        vec3 p1=parametric(t);

        float d1=dot(p1-ro,rd);

        if(abs(ray_to_curve_dis_sq(ro,rd,t)-curve_width_sq)<eps && d1<d0){
            t1=t;
            d0=d1;
        }

        t0+=1./float(num_start_params-1);
    }

    if(t1!=1e38){
        vec3 p1=ro+d0*rd;
        for(int i=0;i<marching_steps;i++){
            for(int j=0;j<num_iterations2;j++){
                t1=parametric_normal_iteration3d(t1,p1);
            }

            p0=parametric(t1);
            d0=dot(p0-ro,rd);
            p1=ro+d0*rd;
        }

        p1-=rd*sqrt(curve_width_sq-dot(p1-p0,p1-p0));
        nor=normalize(p1-p0);

        return true;
    }
    else{
        return false;
    }
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= .5;
    uv.x *= resolution.x / resolution.y;
    
    vec3 ro = vec3(0, 0, 3);
    vec3 rd = normalize(vec3(uv, 0.) - vec3(0,0,1));

    vec3 nor, p0;
    float t0;

    bool hit = parametric_curve_newton_trace(ro,rd,p0,nor,t0);

    if(hit){
        vec3 light = vec3(0, 1, 4);
        
        float dif = clamp(dot(nor, normalize(light - p0)), 0., 1.);
        dif *= 5. / dot(light - p0, light - p0);
        
        #ifdef SHOW_PARAMETER
        glFragColor = vec4(vec3(pow(dif, 0.4545)), 1)*vec4(to_col(t0*2.*pi),1);
        #else
        glFragColor = vec4(vec3(pow(dif, 0.4545)), 1);
        #endif
    }
    else{
        glFragColor = vec4(0, 0, 0, 1);
    }
}
