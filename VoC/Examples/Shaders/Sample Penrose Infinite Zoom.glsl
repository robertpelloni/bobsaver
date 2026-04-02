#version 420

// original https://www.shadertoy.com/view/tltSDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution
#define pi 3.14159
#define tao 6.28318
#define phi 1.6180339
#define rot20(x) cos((x)*tao/20. - vec2(0,pi/2.))

float sdLine(vec2 uv, vec2 a, vec2 abn){
    vec2 x = uv-a;
    vec2 r = abn.yx*vec2(-1,1);
    return dot(r, x - abn * dot(x, abn));
}

float penrose(vec2 uv){
    int type = 0;
    
    float angle = atan(uv.y,uv.x);
    angle = mod(angle + tao/10.,tao/5.) - tao/10.;
    angle = abs(angle);
    uv = length(uv) * cos(angle - vec2(0,pi/2.));
    float r = 0.;
    if(sdLine(uv, rot20(2.), rot20(6.)) > 0. ){
    
        for(int i = 0; i < 16; i++){
            float d0 = sdLine(uv, vec2(1./phi,0), rot20(8.) );
            float d1 = sdLine(uv, vec2(1./phi,0), rot20(3.) );
            float d2 = sdLine(uv, rot20(2.), rot20(9.));
            float d3 = sdLine(uv, rot20(2.), rot20(4.));

            if(d0 > 0.){
                type = 1;
                uv.y = d0 * phi;
                uv.x = d1 * phi;
            } else {
                type = 0;
                uv.x = d2 * phi;
                uv.y = abs(d3) * phi;
            }
            
            r += float(type) / pow(1.2,float(i)) / 6.;
        }
    
    }
    return r;
}

void main(void)
{
    vec2 i = gl_FragCoord.xy;
    float s = 2./R.y;
    vec2 uv0 = (i*2.-R.xy)/R.y / pow(1.6180339, mod(time,4.))/2.2;
    vec2 uv1 = (i*2.-R.xy)/R.y / pow(1.6180339, 4.+ mod(time,4.))/2.2;
    glFragColor = vec4(.5+.5*sin(vec4(8,5,12,0)*(time/1e2 + mix(penrose(uv1),penrose(uv0),  mod(time,4.)/4. ))));
}
