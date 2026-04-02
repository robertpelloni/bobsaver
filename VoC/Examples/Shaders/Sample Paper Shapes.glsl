#version 420

// original https://www.shadertoy.com/view/3ljXRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Most of these comments are helpful
//some maybe not so much.

mat2 rot(float a)
{
 return mat2(cos(a), -sin(a), sin(a), cos(a));   
}
float shadowCircle(vec2 p, float r, float i)
    {
        //hacked: moving the shadow for light direction
        p +=vec2(0.02, 0.02)*rot(time/10.);
        
        //using polor coordinates to make a cool shape : https://thebookofshaders.com/07/
        float a  =atan( p.y,p.x);
        float shape = sin(a*i+i/1.)/10.;
     
        //SS is used as smoothstep range
        //there is a much better way that fabrice told me about.
        //It's in another shader. (Applause)
        float ss = 0.05;
        //shadow created with shape and 1.0-shadow so it returns as black where it should
        float k = 1.0-smoothstep(r-ss, r+ss, length(p/1.5)+shape);
        return pow(k,1.2);
}

float rimCircle(vec2 p, float r, float i)
{
    //using polor coordinates to make a cool shape : https://thebookofshaders.com/07/
    float a  =atan( p.y,p.x);
    float shape = sin(a*i+i/1.)/10.;
    
    //SS is used as smoothstep range
    //there is a much better way that fabrice told me about.
    //It's in another shader. (Applause)
     float ss = 0.0042; 
        
    //a rim range 
    float rim = 0.003;
    //rim is a bigger circle subtracted by a smaller circle to leave just an edge
    float k = smoothstep(r-ss, r+ss, length(p/1.5)+shape);
    //k2 uses "rim" as the thickness of that edge
    float k2 = smoothstep(r-ss+rim, r+ss+rim, length(p/1.5)+shape);
    //here is the subtraction
    k =k-k2;
    //I return it clamped for some reason (applause)
    return clamp(k/2., 0.0, 1.);
}

float Circle(vec2 p, float r, float i)
{
    
    //SS is used as smoothstep range
    //there is a much better way that fabrice told me about.
    //It's in another shader. (Applause)
     float ss = 0.009;
    
    //using polor coordinates to make a cool shape : https://thebookofshaders.com/07/
    float a  =atan( p.y,p.x);
    float shape = sin(a*i+i/1.)/10.;
    //creating the smoothstepped circle
    float k = smoothstep(r-ss, r+ss, length(p/1.5)+shape); 
    //adding the rim circle here even though I do it in main. 
    //I dont' know why I did this but it seems to help! (APPLAUSE)
    return k+rimCircle(p,r-0.001, i);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    //scaling and shifting so it goes from -1 to 1
    uv = uv*2.0-1.0;
    //scaling uv.x to fix screen aspect ratio
    uv.x*=resolution.x/resolution.y;
    vec3 col = vec3(0.5, 0., 0.0);//init with a red color
    //init a texture with rotating coordinate system so the texture moves with the shapes
    float t = 0.0;//vec3(texture(iChannel0,uv/3.*rot(time/40.))).x;
    
    for(float i = 0.0;i<10.;i++){
        //rotate coordinate system with time slowly
        uv*=rot(time/40.);
        t = 0.0;//vec3(texture(iChannel0,uv/3.)).x;
        //add shadow to scene first since it's darkest and is shade of black.
        col *=shadowCircle(uv, 0.2+i/10., i);  
        //the most important part of this effect I think is the changing color brightness between layers, 
        //darkest at bottom although it's not exact since I'm not using a monochrome palette
        col = mix(col, vec3(1., 0.2+i/10., 0.2+i/10.)-t*step(1.,mod(i,2.)), Circle(uv, 0.2+i/10., i));
        //creating a "rim" or a contour at the edges. Shane has a better one.
        col = mix(col, vec3(1.,0.2+i/10.,0.2+i/10.), rimCircle(uv, 0.2+i/10., i)*i/10.);
    }
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
