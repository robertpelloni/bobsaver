#version 420

// original https://www.shadertoy.com/view/tlyBWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//cone tracing explained here: https://www.scratchapixel.com/lessons/advanced-rendering/rendering-distance-fields/basic-sphere-tracer
 
 
 //comment this out to stop rendering the point light (it's quite expensive)
#define renderPointLight 
 //uncomment this to tonemap (reduces washed out highlights but also darkens the image)
//#define toneMap
 //camera position and camera target
vec3 cp=vec3(0.,4.,0);vec3 ct=vec3(2.,3.5,1);
 //max march iterations, max distance (basically far clipping plane),
 //step multiplier dampens raymarch step size to improve blur
float maxI=200.,maxd=50.,stepMultiplier=.5;
 //sample offset for calculating normals
vec2 e=vec2(0.0035,0);
 //light position
vec3 lp,ld=normalize(vec3(-1,-1,-1));
 //colour of spheres and background (darker sphere colours help to hide artifacts),light colour
 //(dont set any of the light colour components to 0, it will look stupid),vignette colour
vec3 sphCol=vec3(0.0,0.7,1),bg=vec3(.9),lc=vec3(1.),vc=vec3(0.,0.2,.3);
 //light brightness
float plb=.7,dlb=1.;
float focalDist=3.,aperture=.02;
 //sphere grid scale
float grid=2.;
 //ambient light level, specular coefficient (shininess)
float amb=.1,specCoeff=400.;
 //camera movement vector
vec3 vel=vec3(1.,0.,1.);
 //speed and mag of sphere wave, speed and radius of of light rotation
float waveSpeed=1.2,waveMag=.4,lightSpeed=1.,lightRad=12.,
 //height of light, magnitude and sped of light's height oscilation
lightHeight=2.,lightOscilationMag=1.,lightOscilationSpeed=.5;
float vignetteStrength=.7,fogStrength=1.;
 //trade off between noise and banding with extreme blur. Must be between 0 and 1.
float sampleOffset=.2; 

 //pseudo random number from float (between 0 and 1)
float hash11(float x){
    return fract(sin(x*835.24+132.124)*123.1433);
}
 //pseudo random number from vec2 (between 0 and 1)
float hash21(vec2 x){
    return fract(sin(x.x*845.24+x.y*554.5243+122.124)*123.143);
}

 //return the co-ordinates of the nearest sphere within the grid
 //used to animate and colour them discretely
vec2 getID(vec3 p){
    return vec2(floor((p.x+grid/2.)/grid),floor((p.z+grid/2.)/grid));
}

 //add a random offset to a given point, with a max distance r from the original point.
 //this is used to add noise to the blur, reducing banding
vec3 rndPt(vec3 c,float r){
    return c+normalize(vec3(hash11(c.z)-.5,hash11(c.x)-.5,hash11(c.y)-.5))*hash11(r+time)*r;
}

 //get distance to world
float map(vec3 p){
    float planeDist=p.y+1.;//distance to ground plane
    p+=vel*time;//apply camera movement
    vec2 id=getID(p);//get discrete co-ordinates of current sphere within grid
    p.y+=sin(id.x+id.y+time*waveSpeed)*waveMag;//animate sphere heights with wave
    p.xz=mod(p.xz+grid/2.,grid)-grid/2.;//mod function creates the infinite grid
    return min(length(p)-1.,planeDist);//return distance to nearest sphere
}

 //calculate normal vector at given point
vec3 norm(vec3 p){
    return normalize(vec3(map(p+e.xyy),map(p+e.yxy),map(p+e.yyx))-map(p));
}

 //calculate the colour at a given point
vec3 shade(vec3 p,vec3 rd){
     //vector from light to point
    vec3 lightVec=p-lp;
     //again, find discrete co-ordinates of nearest sphere
    vec2 id = getID(p+vel*time);
     //direction to light source
    vec3 pld=normalize(lightVec);
     //calculate normal vector at point
    vec3 no = norm(p);
     //multiply light based on squared distance from light source
    float lMult=10./dot(lightVec,lightVec);
     //standard diffuse lighting formula
    float dif=lMult*plb*(exp(max(0.,dot(no,-pld)))-1.);//point light
    dif+=dlb*(exp(max(0.,dot(no,-ld)))-1.);//directional light
     //standard specular lighting formula. 
     //hash21(..)... randomizes the specular exponent (shininess) of each sphere
    float spec=lMult*plb*pow(max(0.,dot(-pld,reflect(rd,no))),hash21(id)*specCoeff+2.);//point light//
    spec+=dlb*pow(max(0.,dot(-ld,reflect(rd,no))),hash21(id)*specCoeff+2.);//directional light//
     //albedo (base colour) of closest sphere
    vec3 al=vec3(smoothstep(.3,.7,hash21(id)))*sphCol;
     //amount of fog based on distance from camera
    float fog=clamp(fogStrength*smoothstep(0.,maxd,length(p-cp)),0.,1.);
     //use all the stuff above to calculate colour
    return mix((dif*lc+amb)*al+vec3(spec),bg,fog);
}

//responsible for rendering the visible point light.
vec3 glow(vec3 f, vec3 rd){
    float glow;
    if (dot(f, lp-cp)>0.){//only needed if light is in front of camera
        vec3 lrd = normalize(lp - cp);//ray direction to point light
        float mind = 0.04;//this doesnt need to be accurate so we can reduce accuracy for performance
        maxd = length(cp - lp);//distance doesnt need to go beyond distance to light
        vec3 p=cp;float td,d=100000.;
        for(int _=0;_<100&&d>mind&&td<maxd;_++){
            d=map(p);td+=d;p+=lrd*d;
        }
        if (td>maxd){//if nothing was hit between camera and light, light is visible
            glow = .06 / length(cross(rd, lp - cp));
        }
    } else{//light is behind camera, just apply glow based on distance
        glow = .06 / length(lp - cp);
    }
    return glow*lc;
}

void main(void) {
     //set aperture and focal distance based on mouse position
    aperture = .1 * mouse.x*resolution.xy.x/resolution.x;
    focalDist = maxd * mouse.y*resolution.xy.y/resolution.y;
    lp=vec3(sin(time*lightSpeed)*lightRad,lightHeight+sin(time*lightOscilationSpeed)*lightOscilationMag,cos(time*lightSpeed)*lightRad);//aniamte point light
     //pixel co-ordinates, mapped to range between -.5 and .5, then scaled by the aspect ratio in the x-axis.
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;uv.x*=resolution.x/resolution.y;
     //this section calculates the ray direction of the pixel.
    vec3 f=normalize(ct-cp);vec3 r=normalize(cross(vec3(0,1,0),f));vec3 u=normalize(cross(f,r));
    vec3 si=cp+f+uv.x*r+uv.y*u;vec3 rd=normalize(si-cp);
     //vertical field of view in radians, used to calculate cone radius later
    float vfov=atan(.5);
     //randomized
    float startDist=hash21(uv+time)*map(cp);
     //variables required for the raymarch
     //i=total raymarch steps,d=current distance,td=total distance
    float i,d,td=startDist;
     //p=current point (starts at camera position) with a random offset to reduce colour banding
    vec3 p=cp+startDist*rd;
     //accumulated colour over all samples, alpha channel used to store amount of cone that has not yet hit the scene
    //vec4 acc=vec4(bg,1.);
    //acc.rgb=vec3(0.);
    vec4 acc=vec4(0,0,0,1);
     //radius of the cone based on width of pixel in world space
    float rad=(2.0*tan(vfov/2.0)) /(resolution.y);
     //very small minimum radius to reduce aliasing at focal point
    float minRad=4./resolution.x;
    for (;i<maxI;i++){ //main raymarching loop.
        d=map(p);
         //current radius of cone. this function makes it shrink until focal point, then grow again.
         //max(minRad*td,...) expression prevents perfect focus to prevent aliasing.
        float cRad=max(minRad*td,rad*td+aperture*abs(td-focalDist));
         //add to total distance, move point
         //step multiplier used to dampen step size, more expensive but more accurate blur.
        td+=d*stepMultiplier;p+=rd*d*stepMultiplier;
         //if geometry is within cone.
        if(d<cRad){
             //naive method of estimating the strength of the current sample .
            float alpha = smoothstep(cRad, -cRad, d);
             //get colour at the current position.
             //This position is offset randomly to trade banding with noise.
            vec3 sampleCol=shade(rndPt(p,d*sampleOffset),rd);
             //add the sample to the cumulative colour
             //acc.rgb=mix(acc.rgb,sampleCol,acc.a*alpha);
            acc.rgb+=acc.a*alpha*sampleCol;
             //reduce the remaining alpha, as some of the cone has hit the scene.
            acc.a*=1.-alpha;
             //if enough of the cone has hit the scene, break out of the loop.
            if (acc.a<.001){break;}
        }
         //if distance is greater than the threshold distance, break out of the loop early
        if(td>maxd){break;}//acc.a=1.;
    }
     //if alpha is greater than 0, the sample colour is mixed with the initial black. We therefore need 
     //to saturate the colour to remove artifacts caused by this.
    acc.rgb*=1./max(.001,(1.-acc.a));
     //blend between object colour and background based on alpha.
    vec3 col=mix(acc.rgb,bg,acc.a);
    
    #ifdef renderPointLight
        col += glow(f,rd);
    #endif
    #ifdef toneMap
        col=1.-exp(-col);
    #endif
     //apply vignette. hash21(...) adds imperceptible to reduce banding.
    col=mix(col,vc,length(uv)*vignetteStrength+hash21(uv+time)*.01);
    glFragColor = vec4(col,1.0);
}
