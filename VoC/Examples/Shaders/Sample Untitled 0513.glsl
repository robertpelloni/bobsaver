#version 420

// original https://www.shadertoy.com/view/wl2Xzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec3 colors[8] = vec3[]( 
    vec3( 1.0, 0.2, 0.0 ),
    vec3( 0.1, 0.2, 0.3 ),
    vec3( 0.1, 0.1, 0.0 ),
    vec3( 0.4, 0.9, 0.8 ),
    vec3( 1.0, 1.0, 0.9 ),
    vec3( 0.4, 0.2, 1.0 ),
    vec3( 0.6, 1.0, 0.9 ),
    vec3( 1.0, 0.1, 0.2 ));

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float rot = 0.1;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x;
    
    
    
rot += time*0.1;
    
    float z = sin(time*0.2)+1.5;
    uv*=z;
    
    uv -= vec2(0.5);
//    uv = rotate2d( sin(time*0.1)*PI ) * uv;
    uv = rotate2d( rot ) * uv;
 uv += vec2(0.5);
    
     uv+= 999.999;
      //  uv.y+=sin(uv.x*5.3)*0.5;

    
    uv.x+=time*0.1;
    float t = 9999. + time * 0.2;
   //t += 0.1*(sin(t*11.5)+1.0);
    vec2 foo = uv;
    
   // foo.y+=sin(foo.x*4.0);
    foo.x += sin(t+5.73+foo.x*1.1)*2.13;
    foo.x -= cos(t-8.73-foo.x*5.1)*.14;

        //t+= sin(foo.x*61.6)*.2;

    float res = 17.0;
    foo.x = floor(foo.x*res) / (res-1.0);
    
   // foo.y += sin(foo.x*32.156) * t;
    t*= sin(foo.x*1.6)* 2.2;
    foo.y += t;
    
    float n = rand(vec2(112.5,floor(foo.y*.1)))*43.01;
    float m = rand(vec2(24.2,floor(foo.y)))*0.28;
  
    if(m>0.03) m+= n;
   // n = min(n,m);
//    foo.y = floor(fract(foo.y*n)+0.5);
    foo.y = mod(foo.y+m,0.43);
   // vec3 cc = colors[int(foo.y*8.0 )];
    vec3 aa = colors[int(foo.y*6.0 )];
    vec3 bb = colors[int(foo.y*6.0+.9 )];
    vec3 cc = mix(aa,bb,foo.y*9.);

    
    /*
    float e = rand(foo);
    vec2 p = uv;

    p.y+=uv.y;
    
    float a = fract(p.y*20.0*e);
    a= floor(a+0.5);
    
    vec2 u = fract(p *20.0);
    float k = length(u-0.5);
    k = smoothstep(0.0,0.2,k);
    
    float s = sin(uv.x);
    */
    vec3 ca= vec3(1.0,0.3,0.1);
    vec3 cb= vec3(1,1,0.4);
    vec3 c = mix(ca, cb, foo.y);
    
    vec3 rgb = hsb2rgb(vec3(foo.y,1.0,1.0));
    
    glFragColor = vec4(cc,1.0);
}
