#version 420

// original https://www.shadertoy.com/view/Ms3fD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ===========================================
// Times tables and mandelbrot set
// a great video by Mathologer
// https://www.youtube.com/watch?v=qhbuKbxJsk8
// ===========================================
//
// Mandelbrot set and modular times tables relation
//
// in order to match times table with the mandelbrot set
// the circle is rotated by amount of -pi/(N-1) where N is the power.
// notice that "N" is also the "times" value for Times table
//
// the circle has a radius of (7+N)/(10+N)
// this is where the cardioid (for N=2) attaches to secondary circle.
// it holds for all N>=2. (teseted by zooming 100x at attachment positions)
//
// ============================================
// all of this was achieved by experiment. i have no mathematical proof 
// or what so ever that this is correct or not. 
// but it seems to be some how working this way.

const float pi = 3.14159265359;
const float epsilon = 1e-5;

const float scale = 1.5;
const float thickness = 3.0*scale;

// mandelbrot set properties
const int iterations = 100;
const float bailout = 100.0;

// times table properties
const int modular = 200;

// shared properties
const float minPower = 0.0; // minimum power of Z.
const float maxPower = 5.0; // maximum power of Z.
const float duration = 50.0; // transition cycle duration in seconds.

vec2 uvmap(vec2 uv) {
    return (2.0*uv-resolution.xy)/resolution.y;
}

vec3 pickColor(float n) {
    return 0.6+0.6*cos(6.3*n+vec3(0,23,21));
}

float smoothout(float dist){
    return smoothstep(thickness/resolution.y,0.0,dist);
}

float smoothfloor(float x) {
    return x - sin(2.0*pi*x)/(2.0*pi);
}

float clock(){
    float rad = acos(cos(2.0*pi*time/duration));
    return (maxPower-minPower)*rad/pi + minPower;
}

float circle(vec2 uv, vec2 C, float r, bool fill)
{
    vec2 p = uv-C;
    float fx = length(p)-r;
    float dist = fill? fx:abs(fx);
    return smoothout(dist);
}

float line(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a, ba = b - a; 
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float dist = length(pa - ba * h);
    return smoothout(dist);
}

vec2 function(vec2 z, float n) {
    float r = pow(dot(z, z), n/2.0);
    float th = n*atan(z.y,z.x+epsilon);
    return r*vec2(cos(th), sin(th));
}

vec2 dfunction(vec2 z, vec2 dz, float n){
    // f(f(z))' = f'(f(z))*f'(z)
    vec2 df = n*function(z, n - 1.0);
    return vec2(df.x*dz.x-df.y*dz.y, df.x*dz.y + df.y*dz.x) + vec2(1,0);
}

float mandelbrotDistance(float r, float dr) {
    float dist = r*log(r)/dr;
    return clamp(pow(dist,0.25),0.0,1.0);
}

vec3 mandelbrot(vec2 uv, float n) {
    vec3 set = vec3(0);
    vec2 c = uv;
    vec2 z = c;
    vec2 dz = vec2(1, 0);
    
    for(int i = 0; i < iterations && dot(z, z) <= bailout; i++) {
        dz = dfunction(z,dz,n);
        z = function(z,n) + c;
    }
    
    float dist = mandelbrotDistance(length(z), length(dz));
    
    if(dot(z, z) > bailout) set = dist+pickColor(n/5.0)/2.0;
    
    return clamp(set*0.8,0.0,1.0);
}

vec3 timesTable(vec2 uv, float times)
{
    vec3 col = vec3(0);
    float len = 2.0*pi/float(modular);
    float r = (7.0+times)/(10.0+times); // radius of the circle
    float phase = -pi/(times-1.0);
    
    col+=circle(uv,vec2(0),r,false);
    
    for(int i = 0; i < modular; i++) {
        float n = float(i);
        
        vec2 c = vec2(cos(n*len+phase),sin(n*len+phase))*r;
        vec2 p = vec2(cos(n*len*times+phase),sin(n*len*times+phase))*r;
        
        col+= circle(uv,c,0.005,true);
        col+= line(uv,c,p)*pickColor(n/float(modular)/3.+time/10.0);
    }
    return clamp(col*0.5,0.0,1.0);
}

void main(void) {
    vec2 uv = uvmap(gl_FragCoord.xy)*scale;
    
    float time = smoothfloor(clock());
    
    vec3 color = mandelbrot(uv,time)
               + timesTable(uv,time);
    
    glFragColor = vec4(color,1.0);
}
