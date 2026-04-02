#version 420

// Conway's Game of Life, by Gabriel Leung

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const mat3 rgb2yiq = mat3( 0.299, 0.595716, 0.211456, 0.587, -0.274453, -0.522591, 0.114, -0.321263, 0.311135 );
const mat3 yiq2rgb = mat3( 1.0, 1.0, 1.0, 0.9563, -0.2721, -1.1070, 0.6210, -0.6474, 1.7046 );

const vec3 initialColor = vec3(1.0, 0.0, 0.0);

vec3 hueShift(float shifter, vec3 inRGB)
{
    // convert rgb to yiq 
    vec3 yiq = rgb2yiq * inRGB;
    // calculate new hue
    float h = (shifter) + atan( yiq.b, yiq.g );

    // convert yiq to rgb
    float chroma = sqrt( yiq.b * yiq.b + yiq.g * yiq.g );
    vec3 rgb = yiq2rgb * vec3( yiq.r, chroma * cos(h), chroma * sin(h) );
    
    return rgb;
}

vec3 getPrevColor(vec2 coord){

    coord = mod(coord,resolution.xy);
    vec3 c = texture2D(backbuffer, coord/resolution).rgb;
    
    vec2 mousePos = mouse * resolution;
    
    /*
if( distance( coord, mousePos) < 15. )
    {
        c = hueShift(time, initialColor);
    }
    */
    if( distance( coord, vec2(resolution.x/3.,resolution.y/2.0 + resolution.y/3.0*cos(1.0*time))) < 10. )
    {
        c = hueShift(time, initialColor);
    }
    if( distance( coord, vec2(2.*resolution.x/3.,resolution.y/2.0 + resolution.y/3.0*sin(1.0*time))) < 10. )
    {
        c = hueShift(time, initialColor);
    }
    
    
    return c;
}

float maxNorm(vec3 v){
    return max(v.x,max(v.y,v.z));    
}

vec3 maxNormalize(vec3 v){
    return v/maxNorm(v);
}

void main( void ) {
    
    vec2 middle = vec2(resolution.x/2.,resolution.y/2.);
    vec3 outColor = vec3(0.);
    
    vec3 prevColor = getPrevColor(gl_FragCoord.xy);
    
    vec2 left = vec2( gl_FragCoord.x -1., gl_FragCoord.y  );
    vec2 right = vec2( gl_FragCoord.x +1., gl_FragCoord.y  );
    vec2 up = vec2( gl_FragCoord.x, gl_FragCoord.y +1.  );
    vec2 down = vec2( gl_FragCoord.x, gl_FragCoord.y -1. );    

    vec2 upleft = vec2( gl_FragCoord.x -1., gl_FragCoord.y+1.  );
    vec2 upright = vec2( gl_FragCoord.x +1., gl_FragCoord.y+1.  );
    vec2 downleft = vec2( gl_FragCoord.x-1., gl_FragCoord.y -1.  );
    vec2 downright = vec2( gl_FragCoord.x+1., gl_FragCoord.y -1. );    
    
    float total = 0.;
    
    vec3 oldLeft = getPrevColor(left);
    if( length(oldLeft)>0.1){ total += 1.; }
    vec3 oldRight = getPrevColor(right);
    if( length(oldRight)>0.1 ){ total += 1.; }
    vec3 oldDown = getPrevColor(up);
    if(length(oldDown)>0.1){ total += 1.; }
    vec3 oldUp = getPrevColor(down);    
    if( length(oldUp)>0.1){ total += 1.; }
    
    vec3 oldul = getPrevColor(upleft);
    if( length(oldul)>0.1 ){ total += 1.; }
    vec3 oldur = getPrevColor(upright);
    if( length(oldur)>0.1 ){ total += 1.;}
    vec3 olddl = getPrevColor(downleft);
    if( length(olddl)>0.1 ){ total += 1.;    }
    vec3 olddr = getPrevColor(downright);        
    if( length(olddr)>0.1){ total += 1.;    }        
    
    
    vec3 newColor = maxNormalize(oldLeft+oldRight+oldDown+oldUp+oldul+oldur+olddl+olddr);
    
    if( (total >= 2.) && (total < 3.) )
    {
        //do nothing
        outColor = prevColor;
    }
    
    if( (total < 2.) || (total > 3.) )
    {
        //turn off
        outColor = vec3(0.0);
    }
    
    if( (total > 2.9) && (total < 3.3) )
    {
        //turn on
        outColor = newColor;
    }
    
    
    
    //if(mouse.x < 0.01){
    //    glFragColor=vec4(0.0,0.0,0.0,1.0);
    //    return;
    //}

    vec4 returnC = vec4(newColor, 1.);
    
    
    returnC = vec4(outColor, 1.);    
    
        
    
    glFragColor = returnC;

}
