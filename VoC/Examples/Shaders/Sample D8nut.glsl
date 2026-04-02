#version 420

// original https://www.shadertoy.com/view/clSyD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sqr(float a){ return a*a; }

//https://en.wikipedia.org/wiki/Lemniscate_of_Bernoulli
vec3 figure8(float t){
    float a = 1.5, st= sin(t), ct = cos(t);
    return vec3(a*ct/(1.+sqr(st)),0,a*st*ct/(1.+sqr(st)));
    //return vec3(2. * cos(t),0,sin(2.*t));
}

float sawtooth(float a){ return a*(1.-sqr(sqr(sqr(a))));}

void main(void)
{
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float pi = 3.14159265359;
    
    float t = 1.*time + 11.5;
    float tC = t*2.*pi/20.;
    vec3 rC = figure8(tC);
    //vec3 rC = vec3(-2,0,0);
    
    vec3 lookat = figure8(tC + .5);
    float zoom = .5;
    
    vec3 lookDir = normalize(lookat-rC),
        //while we are at the ends of the 8, we want to tilt inwards
        dX = normalize(cross(normalize(vec3(-cos(t/40.),1,0)), lookDir)),
        dY = cross(lookDir, dX),
        c = rC + lookDir * zoom,
        i = c + uv.x * dX + uv.y * dY,
        rd = normalize(i-rC);
        
    
    // background
    vec3 col = vec3(0);
    
    vec3 ro = rC;
    float dist1 = 0.,dist2 = 0., bigR = 1., smolR = .9;;
    for(int i = 0; i < 200; i++){
        vec2 center1 = vec2(1,0);
        vec2 center2 = vec2(-1,0);
        dist1 = -sqrt(sqr(length(ro.xz - center1) - bigR) + sqr(ro.y)) + smolR;
        dist2 = -sqrt(sqr(length(ro.xz - center2) - bigR) + sqr(ro.y)) + smolR;
        if(max(dist1, dist2) <= .01){
        float x1,y1,x2,y2,x,y;
            float tG = t/5. ;
            tG = sawtooth(mod(tG,2.)-1.)*3. + .8;
            
            //float tG = -t*2./pi + pi;
            //tG = sin(tG) + 1./2. *sin(2.*tG) + 1./3. *sin(3.*tG) + 1./4. *sin(4.*tG) + 1./5. *sin(5.*tG) + 1./6. *sin(6.*tG) + 1./7. *sin(7.*tG) + 1./8. *sin(8.*tG) + 1./9. *sin(9.*tG);
            //tG *= 2.;
            
            x1 = atan(ro.x+1., ro.z) + tG-pi/2.;
            x2 = atan(ro.x-1., ro.z) - tG + pi/2.;
            y1 = atan(length(ro.xz-center1)-1., ro.y);
            y2 = atan(length(ro.xz-center1)-1., ro.y);
            
            x = mix(x1,x2, smoothstep(-.9,.9,ro.x));
            y = mix(y1,y2, smoothstep(-1.,.1,ro.x));
            
            float px = cos(20.*x);
            float py = cos(20.*y);
            
            
            float bands = cos(y*10.+x*10.);
            float bandwidth = .8*sin(t) - .3;
            float innerBandwidth = .3 * sin(t/3.56) + .7;
            float innerBands =  smoothstep(bandwidth + innerBandwidth,.2 + bandwidth + innerBandwidth,bands);
            float bandlines = smoothstep(bandwidth,.2 + bandwidth,bands) - innerBands;
            
            vec3 bandCol = 0.5 + 0.5*cos((y*10.+x*10.)/10.+vec3(0,2,4));
            
            /*
            float gliders = cos(-y*3. + x*3.);
            gliders = smoothstep(.95,.99,gliders);
            //want only gliders between bands
            float gliderThinning = .8;
            //gliders *= smoothstep(gliderThinning+innerBandwidth,.2 +  gliderThinning + innerBandwidth,bands);
            gliders *= smoothstep(gliderThinning+bandwidth + innerBandwidth,.2 + gliderThinning+bandwidth + innerBandwidth,bands);;
            */
            col = bandlines * bandCol; 
            break;
        }
       
        dist1 = max(dist1, dist2);
        dist1 = max(0.005, dist1);
        ro += rd*0.5 * dist1;
    }
    
        

   

    // Output to screen
    glFragColor = vec4(col,1.0);
}
