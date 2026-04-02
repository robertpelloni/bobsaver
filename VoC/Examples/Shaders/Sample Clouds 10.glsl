#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
 
#define octaves 8

mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
 
float hash( float n ) { return fract(sin(n)*753.5453123); }

float noise( in vec3 x )
{    
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}    
/*
float fbm(vec3 p)
{
    float f;
    f = 0.5000*snoise( p ); p = p*2.02;
    f += 0.2500*snoise( p ); p = p*2.03;
    f += 0.1250*snoise( p ); p = p*2.01;
    f += 0.0625*snoise( p );
    return f;
}
*/
/*
float fbm( vec3 p )
{
        float f = 0.0;
        f += 0.50000*noise( p ); p = p*2.02;
        f += 0.25000*noise( p ); p = p*2.03;
        f += 0.12500*noise( p ); p = p*2.01;
        f += 0.06250*noise( p ); p = p*2.04;
        f += 0.03125*noise( p );
        return f;
}
*/

float fbm(vec3 pos) {
    float f = 0.;
    for (int i = 0; i < octaves; i++) { 
        f += noise(pos) / pow(2.0, float(i + 1)); 
        pos *= 2.01;
    } 
    f = f / (1.0 - 1.0 / pow(2.0, float(octaves + 1))); 
    return f; 
}

float map(float f)
{
    float den = smoothstep(0.1,1.0,f)*2.0;
    return clamp( den, 0.0, 1.0 );
}

void main( void ) {
 
    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    
    //vec2 wind_vec = vec2(time*0.03, 0.0);
    vec2 p = -1.0 + 2.0 * position;// + wind_vec;
    p.x *= resolution.x / resolution.y;
    

    //vec3 rd = normalize(vec3(gl_FragCoord.xy - resolution.xy*.5, resolution.y*0.75)); 
    vec3 ro = vec3(time*0.005, 0. , 0.);
    //vec3 ta = vec3(0.0, 0.0, 0.0);
    // build ray
    //vec3 ww = normalize( ta - ro );
    //vec3 uu = normalize(cross( vec3(0.,1.,0.), ww ));
    //vec3 vv = normalize(cross(ww,uu));
    //vec3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );
    vec3 rd=normalize( vec3( (-1.0+2.0*gl_FragCoord.xy / resolution.xy)*vec2(resolution.x/resolution.y,1.0), 1.0));
    
    
    float t=0.0;
    vec4 col=vec4(0.0);
    vec3 sundir = vec3(-1.0,0.0,0.0);
    
    for(int i = 0; i < 5; i++)
    {
        if( col.a > 0.99 ) break;
        
        vec3 pos = ro + t*rd;
        float f = fbm(40.0*pos + time * 0.03);
        f = map(f);
    
        //vec3 shadow = mix(vec3(1.0), vec3(0.9, 0.8, 0.7), 1.0-f);
        //vec4 res = vec4(mix(vec3(1.0), vec3(0.0, 0.3, 0.6), f), f);
        //res = mix(shadow, res.rgb, f);
        vec4 res = vec4(f);
             res.xyz = mix( vec3(1.0), vec3(0.07,0.1,0.15), res.w );
        
        //float dif =  clamp((res.w - fbm(pos+0.3*sundir))/0.6, 0.0, 1.0 );
            //vec3 brdf = vec3(0.65,0.68,0.7)*1.35 + 0.45*vec3(0.7, 0.5, 0.3)*dif;
        //res.xyz *= brdf;
        
        res.w*= 0.35;
        res*= res.w;
        col = col + res*(1.0 - col.w);
        t+= max(t * 0.5, 0.01);
    }
    //vec3 pos = ro + t*rd;
    
    // Create noise using fBm
    //float f = fbm( 2.0*pos + time * 0.03);
    //f = map(f);
    
    //vec3 shadow = mix(vec3(1.0), vec3(0.9, 0.8, 0.7), col.w);
    //col.rgb = mix(col.rgb, vec3(0.0, 0.3, 0.6), 1.0 -col.w);
    //color = mix(shadow, color, col.w);
    
    //vec3 col = raymarch( ro, rd, gl_FragCoord );
    //col.xyz/=(col.w);
    //col = sqrt( col );
    //col.rgb = mix(col.rgb, vec3(0.0, 0.5, 0.7), col.w);
    vec3 background_color=vec3(0.4, 0.4, 0.7);
        col = min(col, 1.);

 
    glFragColor = vec4( col.rgb, col.w );
    //glFragColor = vec4( color, f );
 
}
