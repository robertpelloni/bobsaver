#version 420

// original https://www.shadertoy.com/view/WtXcWX

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Day whatHHHbbb" by jeyko. https://shadertoy.com/view/WlsyDj
// 2020-06-26 10:11:00

// I will rename these eventually!
// I have no idea what day of my daily challenge it is tho

// Super awesome bayered motion blur from yx https://www.shadertoy.com/view/wsfcWX

#define rot(j) mat2(cos(j),-sin(j),sin(j),cos(j))
#define pi acos(-1.)
#define tau (2.*pi)

#define motionBlurSteps 10 + min(0,frames)

#define moblur

#define tri(j) asin(sin(j))

#define timeStep (1./60.)

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float bayer8(ivec2 uv)
{   
    uv %= 8;
    return 0.0; //texelFetch(iChannel1,uv,0).r;
}

// from iq
float sdTri( in vec2 p, in vec2 q )
{
    p.x = abs(p.x);
    vec2 a = p - q*clamp( dot(p,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = p - q*vec2( clamp( p.x/q.x, 0.0, 1.0 ), 1.0 );
    float s = -sign( q.y );
    vec2 d = min( vec2( dot(a,a), s*(p.x*q.y-p.y*q.x) ),
                  vec2( dot(b,b), s*(p.y-q.y)  ));
    return -sqrt(d.x)*sign(d.y);
}
float sdBox( in vec2 p, in vec2 q )
{
    p = abs(p) - q;
    return max(p.y,p.x);
}
float sdBox( in vec4 p, in vec4 q )
{
    p = abs(p) - q;
    return max(p.y,max(p.x,max(p.z,p.w)));
}

#define pmod(p,j) mod(p - 0.5*(j),(j)) - 0.5*(j)

float ease(float p, float power, float jump, float offs, float end) {
    float j = p;
    p *= offs;
    float r = (1.-cos(pi*p))/2.*jump;
    r = pow(r, power);
    r = mix(r, 1., pow(smoothstep(0.,1.,j),end));
    return r;
}
float eass(float p, float g) {
    float s = p;
    for(float i = 0.; i < g; i++){
        s = smoothstep(0.,1.,s);
    }
    return s;
}
// oh no
#define smease(p,g) ease(p, 1.5, 1.24, 0.76, 1.)
 

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

const float speed = 0.28;
float[] scenes = float[8](4.2*speed,4.2*speed, 4.2*speed, 4.2*speed, 4.2*speed, 4.2*speed, 4.2*speed, 4.2*speed); 

float sumScenes (float cnt){
    float sum = 0.;
    for(float i = 0.; i <= cnt; i++){
        sum += scenes[int(i)];
    }
    return sum;
}

vec3 get(vec2 uv, float t){

    vec3 col = vec3(0);
       
    float d = 10e6;
    
    uv *= 0.85;
    
    
    //t += sumScenes(2.)- 0.2;
    
    t = mod(t, sumScenes(7.)  );
    
    vec2 triW = vec2(0.2,0.2)*1.;
    
    float its = 4.;
    float scene = 0.;
    
    if(t < scenes[0]){
        vec2 p = uv;

        float enva = smease(t/scenes[0]*1.,2.);

        float envb = 1.-smease(t/scenes[0]*1.,3.);

        vec4 q = vec4(p,1,1);
        
        float dt = 10e5;
        
        for(float i = 0.; i <= its; i++){
            vec2 b = p;
            b.y += 0.2*enva;
            
            dt = min(dt,sdTri(b,triW));
            
            p *= rot(tau*i/its);
            
        }
        d = min(d,dt); 

        d = abs(d);
        
    } else if(t < sumScenes(1.)){
        scene = 1.;
        t -= sumScenes(scene - 1.);
        
        vec2 p = uv;

        float enva = smease(t/scenes[int(scene)]*1.,2.);

        float envb = 1.-smease(t/scenes[int(scene)]*1.,3.);

        float envother = smoothstep(0.,1.,enva - dot(uv,uv)/8.);
 
        vec4 q = vec4(p,1,1);

        q.wz *= rot(0.25*pi);
        q.wy *= rot(0.25*pi);
        q.xy *= rot(0.25*pi);
        
        float dt = 10e5;
        
        for(float i = 0.; i <= its; i++){
            vec2 b = p;
            b.y += 0.2;
            
            dt = min(dt,sdTri(b,triW));
            
            p *= rot(tau*i/its);
            
        }
        
        //q = pmod(q,(0.1 ));

        q = pmod(abs(q) -envb*0.1,0.1);

        float db = sdBox(q,vec4(0.03));

        dt = mix(dt,max(dt,db),enva);

        d = min(d,dt); 

        //d /= dpp;
            

    }   else if(t < sumScenes(2.)){
        scene = 2.;
        t -= sumScenes(scene - 1.);
        
        vec2 p = uv;

        float enva = smease(t/scenes[int(scene)]*1.,2.);

        float envb = 1.-smease(t/scenes[int(scene)]*1.,3.);

        float envother = smoothstep(0.,1.,enva - dot(uv,uv)/8.);
 
        vec4 q = vec4(p,1,1);

        q.wz *= rot(0.25*pi);
        q.wy *= rot(0.25*pi);
        q.xy *= rot(0.25*pi);
        
        float dt = 10e5;
        
        for(float i = 0.; i <= its; i++){
            
            vec2 b = p;
            b.y += 0.2 + 0.2*enva;
            
            dt = min(dt,sdTri(b,triW));
            
            p *= rot(tau*i/its);
            
        }
        
        //q = pmod(q,(0.1 ));

        q = pmod(abs(q)  - vec4(0.+ 0.125*enva,+ 0.125*enva,0,0) ,0.1);

        
        
        float db = sdBox(abs(q),vec4(0.03 + 0.01*enva));

        dt = mix(dt,max(dt,db),1.);

        d = min(d,dt); 

        //d /= dpp;

    }   else if(t < sumScenes(3.)){
        scene = 3.;
        t -= sumScenes(scene - 1.);
        
        vec2 p = uv;

        float enva = smease(t/scenes[int(scene)]*1.2,2.);

        float envb = 1.-smease(t/scenes[int(scene)]*1.2,3.);

        float envother = smoothstep(0.,1.,enva - dot(uv,uv)/8.);
 
        vec4 q = vec4(p,1,1);

        q.wz *= rot(0.25*pi);
        q.wy *= rot(0.25*pi);
        q.xy *= rot(0.25*pi);
        
        float dt = 10e5;
        
        p.xy *= rot(2.*pi*enva);
        
        //p = abs(p) - 0.4;
        for(float i = 0.; i <= its; i++){
            
            vec2 b = p;
            b.y += 0.4 + envother*envb*3. ;
            
            for(int j = 0; j < 2; j++){
                b *= rot(0.5*pi*enva);
                b = mix(b,abs(b),enva);
                b -= 0.1*enva;
            }
            //b.x += 0.2;
            
            dt = min(dt,sdTri(b,triW));
            
            p *= rot(tau*i/its);
            
            
        }
        
        //q = pmod(q,(0.1 ));

        q = pmod(abs(q)  - vec4(0.125,0.125,0,0) - 0.02*enva,0.1 );

        
        float db = sdBox(abs(q),vec4(0.04));

        dt = mix(dt, abs(pmod(dt  + 0.5*0.015*enva,0.0)) ,enva);
        

        dt = mix(dt,max(dt,db),1.);

        d = min(d,dt); 

        //d /= dpp;

            

    }     else if(t < sumScenes(4.)){
        scene = 4.;
        t -= sumScenes(scene - 1.);
        
        vec2 p = uv;

        float enva = smease(t/scenes[int(scene)]*1.2,2.);

        float envb = 1.-smease(t/scenes[int(scene)]*1.2,3.);

        float envother = smoothstep(0.,1.,enva - dot(uv,uv)/8.);
 
        vec4 q = vec4(p,1,1);

        q.wz *= rot(0.25*pi);
        q.wy *= rot(0.25*pi);
        q.xy *= rot(0.25*pi);
        
        float dt = 10e5;
        
        //p = abs(p) - 0.4;
        for(float i = 0.; i <= its; i++){
            
            vec2 b = p;
            b.y += 0.4;
            
            for(int j = 0; j < 2; j++){
                b *= rot(0.5*pi);
                b = mix(b,abs(b),1.);
                b -= 0.1; //+ enva*0.1;
            }
            b.x -= 0.1*enva;
            //b.x += 0.2;
            
            dt = min(dt,sdTri(b,triW));
            
            p *= rot(tau*i/its);
            
            
        }
        
        //q = pmod(q,(0.1 ));

        q = pmod(abs(q)  - vec4(0.125,0.125,0,0) - 0.02,0.1 );

        
        float db = sdBox(abs(q),vec4(0.04));

        dt = mix(dt, abs(pmod(dt  + 0.0075,0.0)) ,1.);
        

        dt = mix(dt,max(dt,db),1.);

        d = min(d,dt); 

        //d /= dpp;
            

    }     else if(t < sumScenes(5.)){
        scene = 5.;
        t -= sumScenes(scene - 1.);
       
        vec2 p = uv;

        float enva = smease(t/scenes[int(scene)]*1.2,2.);

        float envb = 1.-smease(t/scenes[int(scene)]*1.2,3.);

        float envother = smoothstep(0.,1.,enva - dot(uv,uv)/8.);
 
        vec4 q = vec4(p,1,1);

        q.wz *= rot(0.25*pi);
        q.wy *= rot(0.25*pi);
        q.xy *= rot(0.25*pi);
        
        float dt = 10e5;
        
        //p = abs(p) - 0.4;
        for(float i = 0.; i <= its; i++){
            
            vec2 b = p;
            b.y += 0.4;
            
            for(int j = 0; j < 2; j++){
                b *= rot(0.5*pi - 0.25*pi*enva);
                b = mix(b,abs(b),1.);
                b -= 0.1;
            }
            b.x -= 0.1;
            
            dt = min(dt,sdTri(b,triW));
            
            p *= rot(tau*i/its);
            
            
        }
        
        //q = pmod(q,(0.1 ));

        q = pmod(abs(q)  - vec4(0.125,0.125,0,0) - 0.02,0.1 );

        
        float db = sdBox(abs(q),vec4(0.04));

        dt = mix(dt, abs(pmod(dt  + 0.0075,0.0)) ,1.);
        

        dt = mix(dt,max(dt,db),1.);

        d = min(d,dt); 

        //d /= dpp;
               

    } else if(t < sumScenes(6.)){
        scene = 6.;
        t -= sumScenes(scene - 1.);
        
      
        vec2 p = uv;

        float enva = smease(t/scenes[int(scene)]*1.1,1.4);

        float envb = 1.-smease(t/scenes[int(scene)]*1.1,2.);

        float envother = smoothstep(0.,1.,enva - dot(uv,uv)/8.);
 
        vec4 q = vec4(p,1,1);

        q.wz *= rot(0.25*pi);
        q.wy *= rot(0.25*pi);
        q.xy *= rot(0.25*pi);
        
        float dt = 10e5;
        
        //p = abs(p) - 0.4;
        for(float i = 0.; i <= its; i++){
            
            vec2 b = p;
            b.y += 0.4;
            
            for(int j = 0; j < 2; j++){
                b *= rot(0.25*pi - 0.25*pi*enva);
                b = mix(b,abs(b),1.);
                b -= 0.1;
            }
            b.x -= 0.1 - 0.3*enva;
            
            dt = min(dt,sdTri(b,triW));
            
            p *= rot(tau*i/its);
            
            
        }
        
        //q = pmod(q,(0.1 ));

        q = pmod(abs(q)  - vec4(0.125,0.125,0,0)*(1. - enva)  - 0.02 - 0.02*enva,0.1 );

        
        float db = sdBox(abs(q),vec4(0.04));

        dt = mix(dt, abs(pmod(dt  + 0.0075,0.0)) ,1.);
        

        dt = mix(dt,max(dt,db),1.);

        d = min(d,dt); 

        //d /= dpp;

    } else if(t < sumScenes(7.)){
        scene = 7.;
        t -= sumScenes(scene - 1.);
        
        vec2 p = uv;

        float enva = smease(t/scenes[int(scene)]*1.1,1.4);

        float envb = 1.-smease(t/scenes[int(scene)]*1.1,2.);

        float envother = smoothstep(0.,1.,enva - dot(uv,uv)/8.);
 
        vec4 q = vec4(p,1,1);

        q.wz *= rot(0.25*pi);
        q.wy *= rot(0.25*pi);
        q.xy *= rot(0.25*pi);
        
        float dt = 10e5;
        
        //p *= rot(0.25*pi*enva);
        
        //p = abs(p) - 0.4;
        for(float i = 0.; i <= its; i++){
            
            vec2 b = p;
            
            b.y += 0.4 - 0.4*enva;
                
            //b.y -= 0.*enva;
            
            b *= rot(1.*pi*enva);
            for(int j = 0; j < 2; j++){
                b = mix(b,abs(b),1. - enva);
                b -= 0.1 - 0.1*enva;
            }
            b.x += 0.2 - 0.2*enva ;
            
            dt = min(dt,sdTri(b,triW));
            
            p *= rot(tau*i/its);
            
        }
        
        
        
        
        //q = pmod(q,(0.1 ));

        q = pmod(abs(q) - 0.04 ,0.1 );

        
        float db = sdBox(abs(q),vec4(0.04));

        dt = mix(dt, abs(pmod(dt  + 0.0075,0.0)) ,1. - enva);
        

        dt = mix(dt,max(dt,db),1. - enva);

        d = min(d,dt); 

    }
    
    
    d = abs(d) - 0.001;
    
    col = mix(col,vec3(1.),smoothstep(dFdx(uv.x),0.,d));
    //col = 1. - col;
    
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;  
    vec3 col = vec3(0);
    
    float edge = dFdx(uv.x)*1.;
    
    
    #ifdef moblur
    for (int i = 0; i < motionBlurSteps  ; ++i) {
        float subsample = bayer8(ivec2(gl_FragCoord.xy));
        float time = time + ((float(i)+subsample)/float(motionBlurSteps)-.5) * timeStep;
        col += get(uv,time);
    }
    col/=float(motionBlurSteps);
    #else
    col += get(uv,time);
    #endif
    //col = clamp(col, 0., 1.);
    col *= 0.999;
    
    //col *= max((1. + 1.*cos(sin(0.25*tau*time/(scenes[0] + scenes[1] ))*tau+length(uv)*2.+vec3(4,2.5,1.5)))*1., 0.);
    //col *= max((1.5 + 1.4*cos(time+length(uv)*2.+vec3(1,1.5,1.5)))*1., 0.);
    
    //col *= 1. - pow(smoothstep(0.,1.,dot(uv,uv)*0.9),0.9)*1.;
    
    //col = 1. - col;
    col = pow(col, vec3(0.454545));
    
    glFragColor = vec4(col,1.0);

}
