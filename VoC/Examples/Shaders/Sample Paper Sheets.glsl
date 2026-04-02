#version 420

// original https://www.shadertoy.com/view/MslcD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv-=0.5;
    uv.x*= resolution.x/resolution.y;
    
    float dist,dist1,dist2,mask,l,final = 1.0;
    //This parameter controls how many sheets are in the picture
    float s = 0.03;
    
    float amp,freq;
    uv.x-=resolution.x/resolution.y;
    
    //This parameter controls when the algorithm stop drawing sheets (-1 is no sheet, 1 all sheets)
    float factorSheets = resolution.x/resolution.y;
    //Optional: very funny :)
    //factorSheets*=sin(0.4*time);
    
    for(float f = -resolution.x/resolution.y;f<factorSheets;f+=s){
        uv.x+=s;
        //This parameter controls the frequency of the waves, modulated by an exp along the x-axis 
        freq = 5.0*exp(-20.0*(f*f));
        //This parameter controls the amplitude of the waves, modulated by an exp along the x-axis 
        amp = 0.12*exp(-7.0*(f*f));
        dist = amp*pow(sin(freq*uv.y+2.0*time+100.0*sin(122434.0*f)),2.0)*exp(-5.0*uv.y*uv.y)-uv.x;
        mask = 1.0-smoothstep(0.0,0.005,dist);

        //Draw each line of the sheet
        dist1 = abs(dist);
        dist1 = smoothstep(0.0,0.01,dist1);
        
        //Draw the shadow of each line
        dist2 =abs(dist);
        dist2 = smoothstep(0.0,0.03,dist2);
        dist2 = mix(0.5,1.0,dist2);
        dist2 *= mask;
        
        //Combine shadow and line
        l = mix(dist1,dist2,mask);
        //Combine the current sheet with the last drawn
        final=mix(l,l*final,mask);
    }
    
 //Add some color   
 //    vec3 white = vec3(1.0,1.0,1.0);
 //    vec3 blue = vec3(0.0/255.0,204.0/255.0,255.0/255.0);
 //    vec3 color = mix(white,blue,final);
 //    glFragColor = vec4(color,1.0);

    glFragColor = vec4(final,final,final,1.0);
}
