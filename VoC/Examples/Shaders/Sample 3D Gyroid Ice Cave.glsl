#version 420

// original https://www.shadertoy.com/view/WtSfzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100. //WE PUT A DECIMEL HERE AND NOT ON MAX STEPS BECAUSE MAX STEPS IS AN INT
                      //WHEREAS MAX_DIST IS A FLOAT
#define SURF_DIST 1e-3 //OUR "SURFACE DIST" IS WHEN THE SPHERE THAT SEEKS A HIT DURING OUR MARCH REACHES A SMALL SIZE, IN THIS CASE .01
                      //THEN WE HAVE A HIT

#define S(a, b, t) smoothstep (a, b, t)

mat2 Rot(float a)
{
    float s = sin(a);
    float c = cos(a);
    
    return mat2(c, -s, s, c); 
}

float sdBox (vec3 p, vec3 s)
{
  p = abs(p)-s; 
    
    return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

float sdGyroid(vec3 p, float scale, float thickness, float bias) 
    {       
        p *= scale;  //WE SCALE THE POSITION TO SCALE THE GYROID. BUT WHENEVER WE MULTIPLY THE POSITION, WE NEED TO DIVIDE IT BY WHAT WE MULTIPLIED. 
        
        return abs(dot(sin(p), cos(p.zxy)) - bias)/scale-thickness; //WE DIVIDE IT HERE.  ALSO !! -- IF PLAYING WITH A 2D GYROID WE CAN
                                                                       //CHANGE THE SHAPE BY MULTIPLYING THE POSITION'S SIN
    }

vec3 Transform(vec3 p)
{
    p.xy *= Rot(p.z*.18); 
    p.z -= time*.1;
    p.y -= .3; 
    
    return p;
}

float GetDist(vec3 p) //THIS TAKES A POINT  IN 3D SPACE AS AN INPUT
    {
                  
        p = Transform(p);  //THIS IS HOW WE'LL MOVE OUR STRUCTURE. WE DON'T WANT TO MOVE OUR CAMERA POSITION BECAUSE THE MORE WE MOVE
                          //OUR CAMERA AWAY FROM THE ORIGIN POINT, THE LESS DETAILED WE'LL GET BECAUSE THIS IS, IN ESSENCE, BUILT AROUND
                          //A RAYMARCHER THAT MARCHES A RAY TO A POINT 
        
        float box = sdBox(p, vec3(1)); 

        float g1 = sdGyroid(p, 5.76, .03, 1.5);
        float g2 = sdGyroid(p, 10.76, .03, .3);
        float g3 = sdGyroid(p, 20.76, .03, .3);
        float g4 = sdGyroid(p, 35.76, .03, .3);
        float g5 = sdGyroid(p, 60.76, .03, .3);
        float g6 = sdGyroid(p, 100.23, .03, .3);

        //float g = min(g1, g2); //Union method of combining gyroids
        // float g = max(g1, -g2); //Subraction method of combining gyroids
        
        g1 -= g2*.4;   //Bumpmap method
        g1 -= g3 *.2;
        g1 += g4 *.2;
        g1 += g5 *.2;
        g1 -= g6 *.1;
       
            
       
       // float d = max(box, g1*.8); //WE MULTIPLY BY A NUMBER LESS THAN 1 TO REDUCE THE STEP SIZE SO WE DON'T OVERSTEP WHEN
                                       //WE ADJUST THE SCALE ABOVE IN sdGyroid.
 
        float d = g1*.6; 
        return d;
    }

float RayMarch(vec3 ro, vec3 rd)
    {
        float dO = 0.; //Distance origin, or how far away we've marched from the origin. 
        
        for(int i=0; i < MAX_STEPS; i++) //Loop that goes until you've reached max # of steps. 
        {
            vec3 p = ro+dO*rd; //Point P is the blue point (
            float dS = GetDist(p); //Distance to the scene. 
            dO += dS; //We add the distance to the scene to how far we've marched away from origin. 
            
            if(dS<SURF_DIST || dO > MAX_DIST) break; //If distance to scene  is smaller than some defined surface distance, we have a hit. 
                                                        //Or if it's past our max distance and we haven't hit anything, we break out of it. 
        }
        return dO; 
    }

vec3 GetNormal(vec3 p) //THIS IS HOW WE FIND THE NORMAL VECTOR, IE THE ORIENTATION OF A SURFACE
                        //ESSENTIALLY BY DOING THE SAME ALGORITHM TO DETERMINE A SLOPE. WE MAKE 2 POINTS
                        //VERY CLOSE TOGETHER, THEN SUBTRACT THE DISTANCE A LITTLE TO THE RIGHT, UP AND
                        //BEHIND THE SURFACE BETWEEN THEM TO FIND WHICH WAY IT'S PORIENTED. 
{
    
    vec2 e = vec2(.01, 0); //THIS IS OUR NEW POINT. OUR X VALUE IS .01 AND OUR Y VALUE IS 0.
    float d = GetDist(p); //THIS IS OUR ORIGINAL POINT IN 3D SPACE WE MADE ABOVE
    
    vec3 n = d - vec3( //THESE ARE THE SUBTRACTIONS TO GIVE US OUR NORMAL 
        GetDist(p-e.xyy), //TO THE RIGHT, IE - .01, 0, 0
        GetDist(p-e.yxy), //UP, IE 0, .01, 0 BECAUSE WE USE THE XY VALUES DEFINED ABOVE, WHEN WE DEFINE VEC2 E
        GetDist(p-e.yyx)); //BEHIND
        
        return normalize(n); 
    
}
        
float GetLight(vec3 p)
        {
            vec3 lightPos = vec3(0,5,6); //HARDCODE THE LIGHT POSITION. FOR NOW WE'LL SAY IT'S AT THESE POINTS. 
            lightPos.xy += vec2(sin(time), cos(time))*2.; 
            vec3 l = normalize(lightPos-p); //THIS CALCULATES WHERE LIGHT IS COMING FROM, FROM THE PERSPECTIVE OF THE SURFACE POINT
            vec3 n = GetNormal(p); 
            
            float dif = clamp(dot(n, l), 0., 1.); //IF WE DON'T CLAMP IT BETWEEN 0 AND 1, THIS ACTUALLY GIVES US A VALUE BETWEEN -1 AND 1
                                                  //WHICH IS FINE WITH A SIMPLE SHAPE LIKE A SPHERE BUT IF WE WANT TO WORK WITH MORE COMPLEX
                                                  //STUFF, IT WOULD GIVE US TROUBLE. SO WE CLAMP IT BETWEEN 0 AND 1 
            
            float d = RayMarch(p+n*SURF_DIST, l); //THIS IS HOW WE CALCULATE SHADOW. WE RAYMARCH BETWEEN SURFACE POINT AND LIGHT POS AND RETURN A VALUE.
            
            if(d<length(lightPos - p)) dif *= .1; //IF THE VALUE WE GET IS SMALLER THAN THE LIGHT POS - SURFACE POSITION, WE KNOW THAT 
                                                  //WE'RE IN SHADOW. TO MAKE A SHADOW, WE JUST TAKE THE LIGHT VALUE DIF AND MULTIPLY IT BY 
                                                  //A SMALL AMOUNT TO CREATE THE SHADOW
            return dif;
        }

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z)
{
    vec3 f = normalize (l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z, 
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d; 
}  
        
vec3 Background(vec3 rd)  //WE ONLY NEED TO CALCULATE OUR BKG'S RD BECAUSE WE DON'T CARE ABOUT WHERE WE ARE, WE ONLY CARE ABOUT WHAT
                           //DIR WE'RE LOOKING IN. 
    
{
    
    vec3 col = vec3(0); 
    float t = time; 
    
    float y = rd.y * .5 +.5; //Here we map our color to the ray direction y and then multiply it so that we lock its value between 0 and 1. 
                            //At 1 (straight), it's its brightest and at 0 (straight down) it's at its dimmest, giving us a gradient in the
                            //middle. 
    
    col += y*vec3(.1, .7, 1)*2.;  //This bakes it in so that our color is brighter the higher our Y is. 
                                  //If we wanted it reverse, we'd do col += (1.-y); 
    
    float a = atan(rd.x, rd.z); //XZ plane to give us our angle so we can determine our NSEW direction 
    
    float flames = sin(a*10. +t)*sin(a*7.-t)*sin(a*3.); //We find the sin wav of our angle and multiply to get multiple sin waves on our image. 
                                                     //We then marry it to time so it comes in and out on a timer. Then repeat, but 
                                                    //multiply it by negative t so we don't see the movement of the light coming in. Then,
                                                    //we multiply it again by the sin wave of the angle and diminish it so it feels random. 
                                                    //We could keep repeating this again and again to make it feel more and more random, but
                                                    //Ehh. It looks fine now.
    
    flames *= S(.8, .5, y); //We don't want this to reach the poles, so we smoothstep the flame's Y so at .5 it starts fading out
                          //and at .8 it's completely faded out   
        
    col += flames; 
    col = max(col, 0.); //This makes it so our color can never go negative. 
    //col += S(.5, .2, y); 
    return col; 
    
}

void main(void)
{    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy; 
    float t = time; 
    vec3 col = vec3(0);
    
    uv += sin(uv*30.*t)*.0001; //"Heat" distortion    IF REALLY HIGH THEN IT CAN BE USED FOR DOPE MOSAIC STUFF
    vec3 ro = vec3(0,0,-.01); //ray origin, or position of camera   
    ro.yz *= Rot(-m.y*3.14+1.); 
    ro.xz *= Rot(-m.x*6.2831);
    
    vec3 lookat = vec3(0,0,0); 
    vec3 rd = GetRayDir(uv, ro, lookat, .8); //THE FLOAT AT THE END OF THIS IS THE ZOOM FACTOR
    
    float d = RayMarch(ro, rd);
    
    if(d<MAX_DIST) //THIS IS WHERE WE MAKE OUR MATERIAL, WHICH INCLUDES COLOR AND SHADOWS
    {
        vec3 p = ro + rd * d; 
        vec3 n = GetNormal(p); 
        
        float height = p.y; 

        p = Transform(p); 
        
        float dif = n.y * .5+.5; //n.y gives us light from direct above because it's the normal's y. We then wrap it with .5 + .5
                                 //to prevent it shooting us back a negative value, keeping it always between 0 and 1. 
        col += dif*dif;
        
        float g2 = sdGyroid(p, 10.76, .03, .3); //Ambient occlusion.
        col *= S(-.1, .1, g2); //Blackening 
        
        
        //CRACKS: 
        
        float crackWidth = -.01 + S(0., -.5, n.y)*.01; //We set the crack width but then put in the smoothstep to say "If it's between
                                                        //These values (ie 0 and -.5), then make it thicker. In this case, it tranlsates 
                                                        //to being thicker on the bottom than the top.  
        float cracks = S(crackWidth, -.03, g2); //  
        float g3 = sdGyroid(p+t*.1, 5.76, .03, .0);
        float g4 = sdGyroid(p-t*.07, 3.76, .03, .0);
        
        cracks *= g3*g4*30.+.3*S(.0, .3, n.y); //THE LAST NUMBER HERE DETERMINES THE BRIGHTNESS OF THE COLOR IN THE CRACKS
                                               //WE USE SMOOTHSTEP HERE TO KEEP IT FROM GOING FULLY BLACK AT A CERTAIN HEIGHT.
                                               //BECAUSE I WANT THIS TO BE ICE, I WANT IT TO NOT GO FULL BLACK UP TOP, BUT DOWN BELOW IS FINE.
                                               //IF I WANTED THE REVERSE, I'D REVERSE THE NUMBERS. 
        
        
        col += cracks*vec3(.1, .7, 1)*3.; //This allows us to change the color of the cracks in RGB code. Our primary color should
                                          //Always be 1 or greater and no value should be 0 because if it is, if we then multiply the
                                          //colors, it will get funky in not a good way. 
        
        //FLICKERING
        
        float g5 = sdGyroid(p-vec3(t,0,0), 3.76, .03, .0); //The vec3 allows us to determine the direction the flickering happens.
                                                           //We marry it to Time to give it a rhythm. If the T is in X, the flickering
                                                          //goes along the X, if in Y then the Y,  etc.
           
        col += g5*vec3(.1, .7, 1); //determines the color of our flicker
        
        col += S(0., 8., height)*vec3(.1, .7, 1)*2.; //gives us a glow to wash it out. I have the glow start at 0 and reach max at 5
        
            
        
    }
    
    //DEPTH FOG/BACKGROUND: 
    
    col = mix(col, Background(rd), S(0., 9., d)); //This is where we blend our background with our structure.  
   
    col *= 1. -dot(uv, uv); //THIS IS A VIGNETTE. WE MULTIPLY UV BY UV (UV SQUARED) TO GIVE US A BLACK CENTER. TO PUSH IT OUT TO THE EDGES
                            //OF THE SCREEN, WE MULTIPLY IT BY NEGATIVE DOT. 
    glFragColor = vec4(col,1.0);
}
    
    
