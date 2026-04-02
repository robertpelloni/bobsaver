#version 420

// original https://www.shadertoy.com/view/WsVczz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,t) smoothstep(a,b,t)
#define N 80

float pi = 3.141592653589793238462643383;
vec3 snowBlue = vec3(.4);
vec2 XY = vec2(8./9.,.5);

//Coordinate Transformation
vec2 RectToPolar(vec2 uv){
    vec2 pol_uv = vec2(length(uv), atan(uv.x/uv.y));
    float st_a = fract(pol_uv.y/(pi/3.))/(pi/3.) -.5;
    return vec2(pol_uv.x, st_a);
}
vec2 PolarToRect(vec2 st){
    float ratio = pi/6./.5;
    return st.x*vec2(cos(st.y*ratio), sin(st.y*ratio));
}

//Map v to Range(i,f)
float Map(float i, float f, float v){
    if(v > f){
        float a = ceil((v-f)/(f-i));
        return v - a*(f-i);
    } else if (v < i){
        float a = ceil((i-v)/(f-i));
        return v + a*(f-i);
    } else return v;
}
vec2 Rotate(vec2 st, float angle){
    float ratio = pi/6./.5;
    st.y += angle/ratio;
    st.y = Map(-.5,.5,st.y);
    return st;
}
float Line(vec2 pi, vec2 pf, float d, vec2 st){
    vec2 pi_rect = PolarToRect(pi);
    vec2 pf_rect = PolarToRect(pf);
    vec2 st_rect = PolarToRect(st);
    
    vec2 v1 = pf_rect - pi_rect; 
    float l = length(v1);
    vec2 v2 = st_rect - pi_rect;
    vec2 v3 = st_rect - pf_rect;
    float d1 = length(v2);
    float d2 = length(v3);
    float perpD = d1*sqrt(1.-pow((dot(v1,v2)/l/length(v2)),2.));
    
    float x1 = abs(dot(v2,v1)/l);
    float x2 = abs(dot(v3,v1)/l);
    if(x1 < l){
        if(x2 < l){
            if(perpD < d) {
                return S(d,0.,perpD);
            }
        } else if(d1 < d) {
            return 0.;
        }
    } else {
        if (d2 < d) {
            return S(d,0.,d2);
        }
    }

    return 0.;
}
    
//Random with mouse*resolution.xy.x as parameter
float Random(float s){ //[-1,1]
    return fract(cos((mouse.x*resolution.xy.x +.2)*s)*73.17) * 2. - 1.;
}

float SnowFlake(vec2 st, float size, float seed){
    st.x /= size;
    vec2 st_rect = PolarToRect(st);
    
    float ringR = XY.y;
    float ringW = abs(Random(.232*seed)) * .015 + .02;
    float result = 0.;
    result += Line(vec2(0.,0.), vec2(ringR,0.), ringW/2., st);
    float ratio = pi/6./.5;
    float angle = pi/3.;
    float dx = .05;
    
    //Each line
    for(float x = 0.02; x < ringR; x+= .05){
        float r = x;
        float l = (ringR-r)*r*2.5*abs(Random(r*seed));
        float c = pow(pow(l,2.) + pow(r,2.) - 2.*l*r*cos(pi -angle),.5);
        float angle2 = asin(sin(pi -angle)/c*l);
        result += Line(vec2(r,.0), vec2(c,angle2/ratio), ringW, vec2(st.x,abs(st.y)));
    }
    return result;
}
void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= vec2(.5);
     uv.x *= resolution.x/resolution.y;
    float t = time*.2;
    
    float ratio = pi/6./.5;
    
    vec3 col = vec3(.0,.0,.1);
    for(int i = 0; i < N; i++){
        //speed
        float vy = abs(Random(float(i)*3.))*.5 + .1;
        float vx = sin((float(i)+t)/2.)*.5;
        float va = Random(float(i)*7.)*.5 + .2;
        
        //size
        float size = abs(Random(float(i)*12.));
        if(float(i) < float(N)* .1) {
            size *= .4;
        } else if(float(i) < float(N) * .7){
            size *= .3;
        } else size *= .25;
        
        //position
        vec2 XY_ = XY + XY*size;
        vec2 orgOffset = vec2(Random(float(i))*.8, Random(float(i)*2.)*.5);
        vec2 moveOffset = vec2(vx,vy*t);
        vec2 offset = orgOffset + moveOffset;
        offset.y = Map(-XY_.y,XY_.y, offset.y);
        offset.x = Map(-XY_.x,XY_.x, offset.x);
        vec2 pos = uv + offset;
        
        vec2 st = RectToPolar(pos);
        st = Rotate(st, pi * va*t);
        col += SnowFlake(st, size, float(i))*snowBlue*pow((size)/.4,2.);
    }
    
    glFragColor = vec4(col,1.0);
}
