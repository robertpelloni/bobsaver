#version 420

// original https://www.shadertoy.com/view/wdGGRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    //OPTIONS: (0) NONE, (1) BREATHE, (2) DISTORT, (3) BREATHE-MOVE,
    //(4) MOVE, (5) XSIN, (6) SCAPE, (7) 2001, (8) CONVEX-ZOOM, (9) CONCAVE-ZOOM
    //(10) CONCAVE
    int option = 7;
    float tme = time*.5;
    float scale = 0.125;
   
    vec2 adjVec = vec2((sin(tme)*.5), (cos(tme)*.5));
    vec2 uv = gl_FragCoord.xy/resolution.xy;    
    vec2 uvM;
    float posMod;
    switch(option){
        case 1:
            uvM = mod(uv + normalize(uv-0.5)*adjVec, scale);
            break;
        case 2:
            uvM = mod(uv + normalize(uv*uv-0.25)*adjVec, scale);
            break;
        case 3:
            uvM = mod(uv*(uv.y) + normalize((uv-.5) + adjVec*.667)*adjVec, scale);
            break;
        case 4:
            uvM = mod(uv + adjVec, scale);
            break;
        case 5:
            uvM = mod(uv*sin((uv.x)*3.1416), scale);
            break;
        case 6:
            uvM = mod(uv + uv*tan(pow(length(uv),abs(sin(adjVec.x)*30.*uv.x))), scale);
            break;
        case 7:
            scale *= 2.;
            posMod = fract(tme/5.);
            if(uv.x>0.5){
                uv.x=1.-uv.x;
            }
            //uv.x -= sin(uv.x)/8.-(pow(0.5-uv.x,-1.));
        
            uv.x += (pow(0.525,-1.))/2500.; //+ .14*(0.5-uv.x);
            uv.x -=(pow(0.525-uv.x,-1.))/2500.;
            //uv.x -= sin(uv.y*30.+sin(tme)*20.)*2.*(.5-uv.x)*(pow(0.5-uv.x,1.4))/14.;
        
            uv.y = uv.y-.5 - sin(tme/2.)*.65;
            
        
            uvM = mod(uv*tan((mod((sin(uv.x)),0.5))*3.1416)+vec2(posMod*5.,(1.-sin(tme/2.+4.7124)/2.+.5)*uv.y), scale);
            //uvM = mod(uv*tan((mod((sin(uv.x)),0.5))*3.1416)+vec2(1.,uv.y), scale);
            break;
        case 8:
            uv = (uv-.5)*length(uv-0.5)*adjVec.x*5.;
            uvM = mod(uv, scale);
            break;
        case 9:
            posMod = abs(cos(tme/3.))*.9 + .1;
            //uv = vec2(pow((uv.x-.5)*length(normalize(uv-0.5))*5., -.05)*posMod, pow((uv.y-.5)*length(normalize(uv-0.5))*5., -.05)*posMod);
            //uv = vec2(pow((uv.x-.5)*length(uv-0.5)*5., -.07)*posMod*2., pow((uv.y-.5)*length(uv-0.5)*5., -.07)*posMod*2.);
            uv = vec2(pow(abs(uv.x-.5)+length(uv-.5), -.07)*posMod*2., pow(abs(uv.y-.5)+length(uv-.5), -.07)*posMod*2.);
            uvM = mod(uv, scale);
            break;
        case 10:
            float zoomMult = pow(5., .5);
            //uv = vec2(pow((uv.x-.5)*length(normalize(uv-0.5))*5., -.05)*posMod, pow((uv.y-.5)*length(normalize(uv-0.5))*5., -.05)*posMod);
            //uv = vec2(pow((uv.x-.5)*length(uv-0.5)*5., -.07)*posMod*2., pow((uv.y-.5)*length(uv-0.5)*5., -.07)*posMod*2.);
            uv = vec2(pow(abs(uv.x-.5)+length(uv-.5), -.07)*zoomMult*2., pow(abs(uv.y-.5)+length(uv-.5), -.07)*zoomMult*2.);
            uvM = mod(uv, scale);
            break;
        default:
            uvM = mod(uv, scale);
    }
    uv = normalize(uvM-vec2(scale/2.))*(adjVec+vec2(.5));

    if(mod(floor((uv.x)/scale),2.) == 0.)
            uvM.x = scale - uvM.x;
    if(mod(floor((uv.y)/scale),2.) == 0.)
            uvM.y = scale - uvM.y;

    uvM += adjVec*length(uvM + adjVec - vec2(0.5));

    // Time varying pixel color
    vec3 col = vec3(0.5 + 0.5*tan((cos(tme)+2.)*8.*(uvM.x/sin(uvM.y+0.2+(cos(tme)/2.+1.)))),
                    0.5 + 0.5*tan((sin(tme*1.2)+2.)*8.*(uvM.x/sin(uvM.y+0.2+(cos(tme)/2.+1.)))),
                    0.5 + 0.5*tan((cos(tme*1.3)+3.)*8.*(uvM.x/sin(uvM.y+0.2+(sin(tme)/2.+1.)))));
    // Output to screen
    glFragColor = vec4(col,1.0);
}
