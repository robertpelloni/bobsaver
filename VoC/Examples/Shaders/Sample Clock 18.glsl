#version 420

// original https://www.shadertoy.com/view/3d2GWc

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI2 6.28318530718

const vec3 green= vec3(0.,1.,0.);
const vec3 black= vec3(0.);
const vec3 white= vec3(1.0);

vec2 rotate( vec2 v, float angdeg) {
    float angrad= radians(angdeg);
    float c= cos(angrad);
    float s= sin(angrad);
    return mat2(c,-s,s,c)*v;
}

float sdCircle( vec2 p, float r ) {
  return length(p) - r;
}

float sdTriangle( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2 ){
    vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
    vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;

    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                     vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                     vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));

    return -sqrt(d.x)*sign(d.y);
}

float sdAnnularShape( in float dist, in float r ){
  return abs(dist) - r;
}

vec2 pol2cart(vec2 v) {
    return v.x*vec2(cos(v.y),sin(v.y));
}

//http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-resolution.xy/2.)/min(resolution.y,resolution.x);
    vec3 col= black; // background color
    float smoothing= 0.003; //antialiasing
    
    //time = date.w // true time in seconds
    vec3 hms= vec3(date.w / 60.0 /60.0, floor(mod(date.w / 60.0, 60.0)), floor(mod(date.w, 60.0)));
    // convert to angle
    hms= vec3(mod(hms.x,12.)/12., hms.yz/60.);
    
    //circle
    float radius= 0.4;
    vec2 center= vec2(0.,0.);
    uv-=center;
    //digits
    float i = round(atan(uv.y, uv.x) * 12.0 / PI2);
    float angle = (PI2 / 12.0) * i;   
    float circd= sdCircle(uv-vec2(cos(angle), sin(angle))*radius, radius/50.);
    //float circd= sdAnnularShape(sdCircle(uv, radius), radius/100.);
    //col+= smoothstep(circd-0.005,circd,0.);

    
    //triangle
    vec3 anghms= (0.25-hms)*PI2+ vec3(0.,0.0001,0.0002); // prevents degenerate case
    vec2 p0 = pol2cart(vec2(radius, anghms.x));
    vec2 p1 = pol2cart(vec2(radius, anghms.y));
    vec2 p2 = pol2cart(vec2(radius, anghms.z));
    float triangd= sdTriangle(uv, p0,p1,p2);
    float anntri= sdAnnularShape(triangd, radius*0.01);
    //col= mix(col, black, smoothstep(triangd-smoothing,triangd,0.));
        

    //endpoints
    float circd0= sdCircle(uv-p0, radius*0.15);
    float ann0= sdAnnularShape(circd0, radius*0.005);
    float circd1= sdCircle(uv-p1, radius*0.1);
    float ann1= sdAnnularShape(circd1, radius*0.005);
    float circd2= sdCircle(uv-p2, radius*0.05);
    float ann2= sdAnnularShape(circd2, radius*0.005);

    // dots
    float freq= 20.;
    vec2 uv2= freq*rotate(uv ,45.) ;
    uv2= 2.*fract(uv2)-1.;

    col= mix(col, hsv2rgb(hms.zxy),float(triangd<0.) *(1.-smoothstep(0.45,0.55,length(uv2))));
    col= mix(col, 0.6*white, smoothstep(anntri-smoothing,anntri,0.));
    
    col= mix(col, black, smoothstep(circd0-smoothing,circd0,0.));
    col= mix(col, hsv2rgb(vec3(hms.x,1.,1.)), smoothstep(ann0-smoothing,ann0,0.));
    col= mix(col, black, smoothstep(circd1-smoothing,circd1,0.));
    col= mix(col, hsv2rgb(vec3(hms.y,1.,1.)), smoothstep(ann1-smoothing,ann1,0.));
    col= mix(col, black, smoothstep(circd2-smoothing,circd2,0.));
    col= mix(col, hsv2rgb(vec3(hms.z,1.,1.)), smoothstep(ann2-smoothing,ann2,0.));
    col= mix(col, 0.6*white, smoothstep(circd-smoothing,circd,0.));

    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
