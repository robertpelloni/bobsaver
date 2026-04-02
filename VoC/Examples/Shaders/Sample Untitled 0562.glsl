#version 420

// original https://www.shadertoy.com/view/tdffDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sin01(float val, float speed){
  return val * (1. + sin( speed * time ) /2.);
}

// --------[ Original ShaderToy begins here ]---------- //
vec3 palette(float d){
  float random = .01 * sin01( 50. , 2. );
    return mix(vec3(random * 0.2, 0.7,random * 0.9), vec3(1., random / 5. ,1.), d);
}

highp float rand(vec2 co)
{
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

vec2 rotate(vec2 p,float a){
      float c = cos(a);
    float s = sin(a);
    return p*mat2(c,s,-s,c);
}

float map(vec3 p){
    for( int i = 0; i<8; ++i){
        float t = time * sin01(.05,.0001) * 0.5;
        p.xz = rotate(p.xz, t);
        p.xy = rotate(p.xy, t*.89);
        p.xz = abs(p.xz);
        p.xz-= .5;
    }
    return dot(sign(p),p)/5.;
}

vec3 rm (vec3 ro, vec3 rd){
    float t = 0.;
    vec3 col = vec3(0.);
    for(float i = 0.; i < 64.; i++){
            vec3 p = ro + rd * t;
        float d = map(p) * .5;
        if(d<0.02){
            // break;
        }
        if(d>100.){
            break;
        }
        // col+=vec3(0.6,0.8,0.8)/(400.*(d));
        float varyingD = 600. + ( 300. * (1. + sin( 2. * time ))/2. );
        col+= palette( length(p) * .1) / ( varyingD * d);
        t+=d;
    }
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - (resolution.xy/2.))/resolution.x;

      vec3 ro = vec3(0.,0.,-50.);
    ro.xz = rotate(ro.xz, time * (.0001 * sin( time * .0001 ) ) );

    vec3 cf = normalize(-ro);
    vec3 cs = normalize(cross(cf, vec3(0.,1.,0.)));
    vec3 cu = normalize(cross(cf,cs));

    vec3 uuv = ro + cf * 4. + uv.x * cs + uv.y * cu;

    vec3 rd = normalize(uuv-ro);

    vec3 col = rm(ro,rd);

    glFragColor = vec4(col,1.);
}
