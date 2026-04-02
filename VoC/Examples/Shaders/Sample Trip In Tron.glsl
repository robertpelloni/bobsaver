#version 420

// original https://www.shadertoy.com/view/MdlyR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: ocb
// Title: Trip in Tron 2
// testing reflection, transparency and glow

#define PI 3.141592653589793

// Global
// object def
// sphere A and B
vec3 sphAO;
float sphAR;
vec3 sphBO;
float sphBR;
float ground;

float random (in vec2 _st) {                         
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))* 
        43758.5453123+time*.1);
}

vec2 truchetPattern(in vec2 st, in float index){
    
    if (index > 0.75) {
        st = vec2(1.) - st;
    } else if (index > 0.5) {
        st = vec2(1.0-st.x,st.y);
    } else if (index > 0.25) {
        st = 1.0-vec2(1.0-st.x,st.y);
    }
    return st;
}

bool groundImpact(inout vec3 pos,in float gndSurface, in vec3 N_ray, out vec3 N_normGnd){
    bool impact = false;
    
    float t = ((gndSurface-pos.y)/N_ray.y);
    if (t > 0.){
        impact = true;
        pos = pos + t*N_ray;
        N_normGnd = vec3(0., 1., 0.);
    }
    return impact;
}

float sphereImpact(inout vec3 pos, in vec3 sphO, in float sphR, in vec3 ray, out vec3 normSph){
    
    float t_dmin = 0.;
    float taux = 0.;
    vec3 delta = pos - sphO;

    // Sphere interception
    // pre-calculation
    float a = dot(ray,ray);
    float b = dot(delta, ray);
    float d = b*b - a*(dot(delta,delta) - sphR*sphR);
    if (d >= 0.){
        float Vd = sqrt(d);
        float t = min( (-b + Vd)/a,
                       (-b - Vd)/a ) ;
        if (t > 0.){
            t_dmin =  - b / a;
            vec3 pos_dmin = pos + ray*t_dmin;
               taux = min(1./( (length(pos_dmin - sphO)/sphR) +.8)-0.8, 1.) + .5*pow(length(pos_dmin - sphO)/sphR,4.);
            pos = pos + ray*t;
            normSph = normalize(pos - sphO);
        }
    }
    return taux;    // return color index for the glow (center and surface)
}

vec3 groundColor(in vec3 pos){
    vec3 col= vec3(0.);
    
        vec2 ipos = floor(vec2(pos.x,pos.z)*.1);  // integer
        vec2 fpos = fract(vec2(pos.x,pos.z)*.1);  // fraction
        vec2 tile = truchetPattern(fpos, random( ipos ));        // generate Maze
        vec2 tileXL = truchetPattern(fract(vec2(pos.x,pos.z)*.1), random( floor(vec2(pos.x,pos.z)*.1) ));        // used for impact effect
        
        // Maze
        col.b += .4*(smoothstep(tile.x-0.05,tile.x,tile.y)-smoothstep(tile.x,tile.x+0.05,tile.y));
        col.b += .5*(1.-smoothstep(.0,.1,length(tile-fract(time*.4))));    // Head on top of Truchet pattern
        
        col.rb += .5*(1.-smoothstep(0.,5.*sphAR,length(pos.xz-sphAO.xz)))*(smoothstep(tile.x-0.05,tile.x,tile.y)-
                         smoothstep(tile.x,tile.x+0.05,tile.y));        // grid lag below sphere A
        col.gb += .5*(1.-smoothstep(0.,5.*sphBR,length(pos.xz-sphBO.xz)))*(smoothstep(tile.x-0.05,tile.x,tile.y)-
                         smoothstep(tile.x,tile.x+0.05,tile.y));        // grid lag below sphere B
         
        
        col += (1.-smoothstep(0.,.02,abs(pos.x)));                // thin white line (main line)
        col.rgb += .3*max(0.,1.-atan(abs(pos.x))*2./PI-.1);        // White line glow
        col.r += (1.-smoothstep(0.,.02,abs(pos.z)));                // thin red line (crossing signal)
        
        col.r += max(0.,(1.-smoothstep(0., .6, fract(time*.1+pos.x*0.00025)))*((1.-smoothstep(0.,.02,abs(pos.z))) + max(0.,1.-atan(abs(pos.z))*2./PI-.1)));    //crossing pulse
        col.b += max(0.,(1.-smoothstep(0., .4, fract(time*3.+pos.z*0.01)))*((1.-smoothstep(0.,.02,abs(pos.x))) + max(0.,1.-atan(abs(pos.x))*2./PI-.1)));    //rapid pulse
                
       col.r += 1.*min(.9, smoothstep(0.,1.,(1.-fract(time*.1))
                *( smoothstep(tile.x-0.05,tile.x,tile.y) - smoothstep(tile.x,tile.x+0.05,tile.y)+1.*(1.-smoothstep(.0,.1,length(tileXL-fract(time*2.)))) )
                *(1.-smoothstep(0.,300000.*fract(time*.1), pos.x*pos.x+ pos.z*pos.z))*smoothstep(0.,100000.*(fract(time*.1)), pos.x*pos.x+ pos.z*pos.z)  ));  //impact
                                                                      
       col *= min(.8,10./length(.01*pos))+.2;     // distance fog

    return col;
}

vec3 skyColor(in vec3 ray){
    vec3 col = vec3(0.);
    col += vec3( max((ray.x+1.)/2.*(-4.*ray.y+1.)/2.,0.),.1*(1.-ray.y),.2*(1.-ray.y) );
    return col;
}

int ojectReflect(inout vec3 pos, inout vec3 N_ray, inout vec3 color){
    vec3 posA = pos, posB= pos, N_normPosA = vec3(0.), N_normPosB = vec3(0.);
    float tauxA, tauxB;
    bool A_ok = false;
    bool B_ok = false;
    
    tauxA = 1.3*sphereImpact(posA, sphAO, sphAR, N_ray,N_normPosA);
    tauxB = 1.3*sphereImpact(posB, sphBO, sphBR, N_ray,N_normPosB);
    
    A_ok = bool (tauxA);
    B_ok = bool (tauxB);
    
    if (A_ok) {
        if (B_ok){
            if (length(posA-pos) < length(posB-pos)){        // A and B are one behind the other
                                                            // at the end, both color are mixed
                color += vec3(0.,tauxB,tauxB);                // but first, we must get the reflection on the sphere behind.
                vec3 Sray = reflect(N_ray,N_normPosB);                        // recursivity would be good
                if (groundImpact(posB, ground, Sray, N_normPosB) ){            // but not allowed by my shader
                       color += groundColor(posB);                                // so here we get the ground or sky reflexion
                }                                                            // on the sphere behind
                else {                                                        // color is added at the sphere basic color tauxB
                color += skyColor(Sray);
                   }
                color = mix(vec3(tauxA,0.,tauxA),color,.7);        // finally A and B are mixed
                pos = posA;                                        // and pos and ray of the front sphere is returned.
                N_ray = reflect(N_ray,N_normPosA);
            }
            else{
                color += vec3(tauxA,.0,tauxA);
                vec3 Sray = reflect(N_ray,N_normPosA);
                if (groundImpact(posA, ground, Sray, N_normPosA) ){
                       color += groundColor(posA);
                }
                else {        // ray goes to the sky
                color += skyColor(Sray);
                   }
                color = mix(vec3(0.,tauxB,tauxB),color,.7);
                pos = posB;
                N_ray = reflect(N_ray,N_normPosB);   
            }
        }
        else{
            color.rb += tauxA;
            pos = posA;
            N_ray = reflect(N_ray,N_normPosA);   
        }
    }
    else if (B_ok){
        color.gb += tauxB;
        pos = posB;
        N_ray = reflect(N_ray,N_normPosB);
    }
    
    return int(A_ok)+int(B_ok);
}

void main(void) {
    
    vec2 st = gl_FragCoord.xy/resolution.xy-.5;
    st.x *= resolution.x/resolution.y;
    
    // init global object
    sphAO = vec3(40.*sin(time*.4),15.,60.*cos(time*.3));
    sphAR = 5.;
    sphBO = vec3(80.*sin(time*.4),16.,40.*cos(time*.3));
    sphBR = 6.;
    ground = 0.;
    
    // camera def
    float focal = 1.;
    float     rau = 25.*(sin(time/11.)+1.)+3.*sphAR,
            alpha = -time/5.,
            theta = (sin(time/7.)/2.+.5)*(PI/2.-1.2)-.1;    //rau, alpha, theta camera position   
    
    vec3 camTarget = (sin(time*.2)+1.)*.5*sphAO + (sin(time*.2+PI)+1.)*.5*sphBO;  //target going from sphA to sphB
    
    vec3 screenPos = rau*vec3(-cos(theta)*sin(alpha),sin(theta),cos(theta)*cos(alpha))+camTarget;
    
    vec3 ww = normalize( camTarget - screenPos );
    vec3 uu = cross(ww,vec3(0.0,1.0,0.0) ) ;
    vec3 vv = cross(uu,ww);
    // create view ray
    vec3 N_ray = normalize( st.x*uu + st.y*vv + focal*ww );

    vec3 N_normPos = vec3(0.);
    vec3 pos = screenPos;

    vec3 color = vec3(.0);
    
    // get color on transparency path
    // no object hit, only ground or sky
    vec3 transPos = pos;    
    vec3 transColor = vec3(0.);
    if (groundImpact(transPos, ground, N_ray, N_normPos)){
        transColor = groundColor(transPos);
    }
    else {transColor = skyColor(N_ray);}
    //-------------------------------
    
    // calculate reflection
    if (ojectReflect(pos, N_ray, color)>0){        // first step ray
        ojectReflect(pos, N_ray, color);        // if sphere hit, second step ray
    }
    //-------------------------------
    
    // mix reflection and transparency
    color = mix(color, transColor, .5);
    
    // otherwise no object impacted
    if (groundImpact(pos, ground, N_ray, N_normPos) ){
       color += groundColor(pos);
    }
    else {        // ray goes to the sky
        color += skyColor(N_ray);
    }
    
    glFragColor = vec4(color,1.0);
}
