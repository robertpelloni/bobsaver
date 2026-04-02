#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(in vec3 z){
    float scale = 1.;
    float seed = 1.25;    
    
    for(int i = 0 ; i <8;i++){
    z = -1. + 2.*fract(.5*z+0.5);
        float r = dot(z,z);        
             
        float k = seed / r;
        z *= k;
        scale *= k;
    }    
    return 0.25*abs(z.y)/scale;    
}

vec3 camPath(in float a){
       return vec3(2.772-a,0.824,2.820);
}

vec3 material(in vec3 p) {
    p = abs(.5 - fract(p * 1.1));
    float k, l = k = 0.;
    for (int i = 0; i < 13; i++) {
        float pl = l;
        l = length(p);
        p = abs(p) / dot(p, p) - .5;
        k += exp(-1. / abs(l - pl));
    }
    k *= .18;
    vec3 col = mix(vec3(k * 1.1, k * k * 1.3, k * k * k), vec3(k), .45);    
    return col;
}

vec3 normal(in vec3 p) {
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize(e.xyy * map(p + e.xyy) + e.yyx * map(p + e.yyx) + e.yxy * map(p + e.yxy) + e.xxx * map(p + e.xxx));
}

float shadow( in vec3 ro, in vec3 rd )
{
    float res = 1.0;
    float t = 0.0005;               
    float h = 1.0;
    for( int i=0; i<40; i++ )       
    {
        h = map(ro + rd*t);
        res = min( res, 64.0*h/t );  
        t += clamp( h, 0.02, 2.0 );  
    }
    return clamp(res,0.0,1.0);
}

float ao(const vec3 pos,const vec3 nor) {
    float aodet = .002 * 1.1;
    float totao = 0.0;
    float sca = 10.0;
    for (int aoi = 0; aoi < 5; aoi++) {
        float hr = aodet + aodet * float(aoi * aoi);
        vec3 aopos = nor * hr + pos;
        float dd = map(aopos);
        totao += -(dd - hr) * sca;
        sca *= 0.75;
    }
    return clamp(1.0 - 5.0 * totao, 0.0, 1.0);
}

vec3 lighting(in vec3 pos, in vec3 nor, in vec3 rd ) {
    vec3 a = normalize(vec3(1.0));
    float d1 = max(0.0,dot(-nor, a)); 
    
    vec3 b = normalize(camPath(time));
    float d2 = max(0.0,dot(-nor, b)); 
    return
        (d1*.5)*(vec3(0.0,0.333333,1.0)*pos) +
            (d2*.5)*(vec3(0.0,0.333333,1.0)*pos);
}

float raymarch( in vec3 ro, in vec3 rd )
{
    const float maxd = 50.0;           
    const float precis = 0.001;        
        float h = precis*2.0;
        float t = 0.0;
    float res = -1.0;
    for(int i=0; i<128; i++ )          
        {
        if( h<precis||t>maxd ) break;
        h = map( ro+rd*t );
            t += h;
        }
        if( t<maxd ) res = t;        
    return res;
}

void main( void ) {

    vec2 uv = ( gl_FragCoord.xy / resolution.xy ) + mouse / 4.0;
    vec2 p = gl_FragCoord.xy / resolution.xy - .5;
    vec2 s = p* vec2(1.75, 1.0);
    
    vec3 ro = camPath(time);
    vec3 ta = camPath(time * 1.1);
    
    float roll = 0. ;

        vec3 cw = normalize(ta - ro);
        vec3 cp = vec3(sin(roll), cos(roll),0.);
        vec3 cu = normalize(cross(cw, cp));
        vec3 cv = normalize(cross(cu, cw));

    vec3 rd = normalize(s.x * cu + s.y * cv + .6 * cw);

    float d = raymarch(ro,rd);
    
    vec3 col = vec3(.0);
    
    
    if(d >- 0.1){
        
    vec3 pos = ro + d*rd;
        vec3 nor = normal(pos);        
       
        vec3 mal = material(pos);     
        
        vec3 light = lighting( pos, nor, rd);      
       
    
        
        col = mal*light*exp(-0.2*d);
     
    }
    
    

    glFragColor = vec4(col, 1.0 );

}
