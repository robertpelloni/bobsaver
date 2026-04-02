#version 420

// original https://www.shadertoy.com/view/MsGcRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 mo;
vec2 uv;
float ratio;

vec3 aud;
void main(void)
{
    
    aud = vec3(0.0);//texture(iChannel0, (0.25+vec2(0.0,0.0)) / iChannelResolution[0].xy, -100.0 ).xyz;
    
    vec3 audavg = aud*.2;
    float speed = 0.9420866;//+(sin(time*.1)*.0002+.5);
    float t0 = (-time)*speed;
    float t1 = cos(t0);
    float t2 = 0.5*t1+0.5;
    float zoom=35.;
    float ratio = resolution.x/resolution.y;
    vec2 uv = gl_FragCoord.xy / resolution.xy*1.-0.5;uv.x*=ratio;uv*=zoom;
    vec2 mo = mouse*resolution.xy.xy / resolution.xy*2.-1.;mo.x*=ratio;mo*=zoom;
    
    //mo = aud.xy;
    //mo *= mo;
    //uv += mo*20.;

    
    // uv / mo
    vec2 uvo = uv;//-mo;
    float phase=1.32961+sin(t2*.2);
    float tho = length(uvo)*phase+t1;
    float thop = t0*8.;
    
    // map spiral
       uvo+=vec2(tho*cos(tho-1.025*thop),tho*sin(tho-1.025*thop));
    uvo *= 1.95+(sin(audavg.x)+1.94);
    //uvo -=(heartRaw(gl_FragCoord)*90.)-90.;
    //uvo *=(heartRaw(gl_FragCoord)*12.);
    
    //uvo += ;
    float xSin = sin(time*.5)*3.;
    float ySin = sin(time*.69)*3.;
    uvo.x += sin(tho);
    uvo.y -= sin(tho)+(mix(uv.y, ySin, tho)*.1);
    
    
    // metaball
    float mbr = 30.9;
    float mb = mbr / dot(uvo,uvo)+.25;

    //display
    //float d0 = mb;
    float d0 = mb+(sin(mb)*(((-uvo.x*.05)+(cos(uvo.x*.0625)*1.)+24.*sin(t1*.125))*sin(t0*.123)*.05));
    
    float d = smoothstep(d0*.43,d0+.25,.45);
    
    //vec3 heart = heart(gl_FragCoord);
    //vec4 heartdark =  vec4(-heart.y, -heart.y, -heart.y, -heart.y)*2.;
    //heart.y *= -1.;
    
        // Normalized pixel coordinates (from 0 to 1)
    vec2 uvi = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos((t1*.21)+uvi.xyx+vec3(0,2,4));
    col.r -= .25;
    col.g = max(col.g-.5,.2);
    // Output to screen
    vec4 FragColorX = vec4(col,1.0);
    
    float r = mix(1./d, d, 1.31)+(sin(t2*.022)*.0191)+(sin(uvo.y*.0325)*.25+(uvo.x*.0024));
    float g = mix(1./d, d, 1.95)-(sin(t2*.028)*.4)-(cos(t1*.023)*.4)+((cos(uvo.y*(.03125+((cos(t0*.1))*.03))))*.9);
    float b = mix(1./d, d, 1.14)+(sin(t1*.012)*.1)-(sin(t2*.056)*.8)-(sin(t2*.0307)*1.02-(uv.y*(t2*.032)*.2));
    vec4 c = vec4(r-.5,g,b,1.);//+heartdark;
    
    glFragColor = c * FragColorX;
}
