#version 420

// original https://www.shadertoy.com/view/3sBXDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 bgTopCol = vec3(0.7f,0.9f,1.0f);    
vec3 bgButtomCol = vec3(0.7f,0.75f,0.85f);    

vec3 snowManCol = vec3(1.0f,1.0f,1.0f);
vec3 snowManEyesCol = vec3(0.3f,0.3f,0.35f);
vec2 snowManBodyPos = vec2(310.0f,80.0f);
float snowManHeadHeight = 120.0f;

vec3 snowStormCol = vec3(0.9f,0.95f,1.0f);
vec3 snowStormMiniCol = vec3(0.8f,0.8f,0.95f);
float snowStormSpeed = 0.14f;
float snowStormMiniSpeed = 0.1f;

vec3 groundFrontCol = vec3(0.85f,0.875f,0.95f);
vec3 groundBackCol = vec3(0.9f,0.95f,1.0f);
float addgroundBackHeight =0.01f;
 
float DrawSphere(vec2 pos, float radius, vec2 gl_FragCoord2)
{   
    return (1.0f - step( radius , length(pos - gl_FragCoord2.xy)));      
} 

vec3 ColorBlending(vec3 destCol,vec3 srcCol ,float blendRate)
{   
    return (destCol * (1.0f -blendRate) + srcCol * blendRate);
}  

float Snowstorm(vec2 uv,float border,float fr,float speed)
{
    uv.y += time * speed;
    uv.x +=time * 0.05f;
    
    uv = ((( mod(uv*fr,1.0f) -0.5f)*2.0f)*resolution.xy) /resolution.y;

    return (1.0f - step(border,length(uv)));
}

float SnowGround(float height,vec2 gl_FragCoord,float wave)
{
    float groundHeight = sin((gl_FragCoord.x + wave)*0.01f)*10.0f +height;
    
    return 1.0f - step(groundHeight,gl_FragCoord.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec3 col = bgTopCol * uv.y + bgButtomCol * (1.0f- uv.y);
  
    // ground back
    col =ColorBlending(col ,groundBackCol, SnowGround(80.0f+addgroundBackHeight*time,gl_FragCoord.xy,time*25.0f)); 

    // snowStorm
    col = ColorBlending(col ,snowStormCol ,Snowstorm(uv, 0.25f,12.0f,snowStormMiniSpeed));
    col = ColorBlending(col ,snowStormCol ,Snowstorm(uv, 0.25f,8.0f,snowStormSpeed));   
   
    // snowman body
    col = ColorBlending(col ,snowManCol ,DrawSphere( snowManBodyPos, 80.0f,gl_FragCoord.xy));
    // snowman head
    col = ColorBlending(col ,snowManCol ,DrawSphere( snowManBodyPos + vec2(0.0f,snowManHeadHeight), 70.0f,gl_FragCoord.xy));
    // snowman eyes
    col = ColorBlending(col ,snowManEyesCol ,DrawSphere(snowManBodyPos + vec2(-30.0f,snowManHeadHeight), 10.0f,gl_FragCoord.xy));
    col = ColorBlending(col ,snowManEyesCol ,DrawSphere(snowManBodyPos + vec2(30.0f,snowManHeadHeight), 10.0f,gl_FragCoord.xy));
   
    // ground front
    col = ColorBlending(col ,groundFrontCol, SnowGround(40.0f,gl_FragCoord.xy,100.0f)); 
    
    // post effect
    col += pow(max(0.0f,(0.5f,length((uv-0.5f)*2.0f))),4.0f) *0.05f;   
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
