#version 420

// original https://www.shadertoy.com/view/WlcyRj

uniform int frames;
uniform float time;

out vec4 glFragColor;
//uniform vec2 mouse;
uniform vec2 resolution;

// Black Lines are the main tiling
// White lines are the dual 

// Honestly, the code isn't a very tidy read, so you might want to look at some other resources
// if you'd like to do this yourself.

// Here's some other takes on Wythoff tiling:
// by fizzer: https://www.shadertoy.com/view/3tyXWw
// by mla: https://www.shadertoy.com/view/ttGSRy

#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define pal(a,b,c,d,e) ((a) + (b)*sin((c)*(d) + (e)))
#define pi acos(-1.)
#define tau (2.*pi)

float id = 0.;

vec2 refl(vec2 p, vec2 reflectionPlane, float offs){
    float dotReflectionPlane = dot(p + reflectionPlane*offs,reflectionPlane);
    dotReflectionPlane = max(abs(dotReflectionPlane),0.)*sign(dotReflectionPlane);
    p -= min(dotReflectionPlane,0.)*2.*reflectionPlane;
    id+= float(dotReflectionPlane<0.)*4. + float(dotReflectionPlane<0.)*dotReflectionPlane*.84;
    return p;
}

vec3 get(in vec2 FragCoord){
    vec3 col = vec3(0);
    id = 0.;
    
    vec2 uv = (FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    uv *= 3. + sin(time*0.4)*0.2;
    float cntSides = 3.;
    
    //if(mouse*resolution.xy.x/resolution.x<0.33){
    //    cntSides = 3.;
    //} else if(mouse*resolution.xy.x/resolution.x<0.66){
    //    cntSides = 4.;
    //} else {
    //    cntSides = 6.;
    //} 
    
    float cntIters = 20.;
    
    vec2 p = uv;
    
    
    float radiusInscribedCircle = 0.4;
    
    for(float iter = 0.; iter < cntIters; iter++){
        vec2 sidePlane = vec2(1.,0.);
        
        for(float side = 0.; side < cntSides; side++){
            sidePlane *= rot(tau/cntSides);
            
            p = refl( p,sidePlane,radiusInscribedCircle);

        }
        vec2 reflectionPlane = vec2(1.,0.);
        for(float side = 0.; side < cntSides; side++){
            
            
            p = refl( p, reflectionPlane, 0.);
            
            
            reflectionPlane *= rot(pi/cntSides);

        }

    }
    
    
    float hexCircumCircleRadius = radiusInscribedCircle/(sqrt(3.)/2.);
    float triangleRadius = radiusInscribedCircle*1.44;
    
    col += pal(0.5,vec3(0.5,.3,0.1),vec3(1.5,2.6,4.4),1.,id + time );
    
    float d = length(p.y - radiusInscribedCircle * (
                + 1.*float(cntSides == 4.)
                + triangleRadius*float(cntSides == 3.)
                ) 
            );
            
    
    vec2 dualness = mix(vec2(0),
        0.7 + 0.1*vec2(sin(time), cos(time)),
        0.// + mouse*resolution.xy.y/resolution.y
    );

    if (cntSides == 6.){
        d = length((p*rot(pi/6.)).y - hexCircumCircleRadius*0.85);                
    }

    // Positioning duals
    if(cntSides == 3.){
        // some number crunching here
        p.x += 0.175*triangleRadius;
        p = refl( p, -vec2(0,1.), hexCircumCircleRadius*0.5 );
        p.x -= 0.175*triangleRadius;
        
        
        p.y -= dualness.y*0.5*hexCircumCircleRadius;
        
        p.x -= 0.5*dualness.x*0.7*triangleRadius;
        
        //p.x -= 0.01
        //p.x -= 0.7*dualness.x*0.66*triangleRadius;
        //p.y += -0.5*dualness.y*0.45*triangleRadius;
        
        
    } else if(cntSides == 6.){    
        p.y -= 1.5*dualness.y*0.6*hexCircumCircleRadius;
        p.x -= 1.5*dualness.x*0.15*radiusInscribedCircle;
    
        p *= rot(0.666*pi*float(cntSides==6.));  // the number of the beast .-.

    }  else if(cntSides == 4.) {
        p.x -= dualness.x*0.4*radiusInscribedCircle;
        p.y -= dualness.y*0.9*radiusInscribedCircle;
    }
    
    
    float dDual = max(length(p.x), - p.y );
    dDual = min( dDual, 
            max( length(p.y), p.x)
        );
        
    p *= rot(0.325*pi*float(cntSides==3. || cntSides==6.));
    p *= rot(0.25*pi*float(cntSides==4.));
    
    
    dDual = min( dDual, 
            max( length(p.y), -p.x)
        );
    if (cntSides == 6.){
        //dDual = d + 0.*(d = dDual); // oh my, not the prettiest line of code, haha.  
    }
    
    
    d = min(d, length(p) - 0.03);
    
    d -= 0.01;
    dDual -= 0.007;
    
    col = mix(col,vec3(1.), smoothstep(dFdx(uv.x), 0., dDual));
    col = mix(col,vec3(0.), smoothstep(dFdx(uv.x), 0., d));
    
    
    col = max(col,0.);
    return col;
}
void main(void)
{
    vec3 col = vec3(0);
    
    
    float aa = 3.;
    
    for(float i =0.; i < aa*aa + min(float(frames),0.)   ; i++){
        col += get(gl_FragCoord.xy + 0.66*vec2(mod(i,aa),floor(i/aa))/aa);
    }
    col /= aa*aa;    
    
    //col = mix(col, smoothstep(0.,1.,col*vec3(1.6,1.2,1.4)),0.5);
    
    col = pow(col,vec3(0.8545));
    glFragColor = vec4(col,1.0);
}
