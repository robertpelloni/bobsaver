#version 420

// original https://www.shadertoy.com/view/llSSDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 col =vec3(0., 0., 0.);
vec2 uv;
const float iter = 64.;
float divAng = 24.; // should be factors of 360
#define rotMat(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define PI 3.14159265359
#define RAD 0.01745329251
#define DEG 57.2957795131

float nearestMult(float v, float of) {
    v-= (mod(v, of)) * sign(of/2. - (mod(v,of)));
    v-=mod(v,of);
    return v;
}

vec2 nearestMult(vec2 v, float of) {
    v.x = nearestMult(v.x, of);
    v.y = nearestMult(v.y, of);
    return v;
}

void main(void)
{
    
    uv = ( gl_FragCoord.xy / max(resolution.x, resolution.y));
    float mX = resolution.x / max(resolution.x, resolution.y);
    float mY = resolution.y / max(resolution.x, resolution.y);
    vec2 initCenter = vec2(mX/2., mY/2.);
    uv-=initCenter;
    uv/=.9;;
    vec2 center = vec2(0.,0.);
    float circRad = .23;    
    float sCircRad = .045;
    float rat =sCircRad / circRad;
    vec2 dir = normalize(uv - center);
    vec2 rightVec = vec2(1., 0.);
    float dotVal = dot(dir, rightVec);
    float ang =  acos(dotVal) * DEG * ((uv.y - center.y)>=0.?1.:-1.);// sign(uv.y - center.y);
    ang= ang<0.?ang+360.:ang;
    //ang+=time*DEG;
    
    ang = nearestMult(ang, divAng);
    vec2 nCenter = center +
        //rotMat(time)*
        vec2(circRad*cos(ang*RAD), circRad*sin(ang*RAD));
    float dist = distance( nCenter, uv);
    float moder = 2.;
    vec3 tcol,tcol2, tcol3;
    for(float i=0.;i< iter;i+=1.) {
    
        if(abs(dist )<=sCircRad ) {
            
            col +=  2.2* vec3(sCircRad, sCircRad+circRad+dist, circRad);
            
                        
        }
        center = nCenter;
        circRad = sCircRad + sCircRad*(.5+abs(sin(time/10.)*3.));// + cos( 1.));
        sCircRad = circRad * rat;
        
        dir = normalize(uv - center);
        dotVal = dot(dir, rightVec);
        ang =  acos(dotVal) * DEG * ((uv.y - center.y)>=0.?1.:-1.);
        ang= ang<0.?ang+360.:ang;
        //ang+=time*DEG;
        ang-= (mod(ang, divAng)) * sign(divAng/2. - (mod(ang,divAng)));
        ang-=mod(ang, divAng);
        nCenter = center +
            //rotMat(time)*
            vec2(circRad*cos(ang*RAD), circRad*sin(ang*RAD));
        dist = distance( nCenter, uv);
    
    }
    
    glFragColor = vec4( col, 1.0 );
    
}
