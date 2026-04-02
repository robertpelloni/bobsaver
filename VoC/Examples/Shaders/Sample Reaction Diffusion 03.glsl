#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec3 nrand3( vec2 co )
{
    vec3 a = fract( cos( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
    vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
    vec3 c = mix(a, b, 0.5);
    return c;
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float averageForRadius(vec2 co, float radius) 
{
    float average = float(0);
    float sampleSize = 1.0;
    int n = 0;
    float y2 = 0.0;
    float x2;
    float x3;
    for (int i = 0; i < 50; i++) {
        if (y2 > radius) break;
        x2 = sqrt(pow(radius, 2.0) - pow(y2, 2.0));
        x3 = (x2 - sampleSize) * -1.0;
        for (int k = 0; k < 50; k++) {
            if (x3 >= x2) break;
            vec2 spoint = vec2(x3 / resolution.x, y2 / resolution.y);
            average += texture2D(backbuffer, co + spoint).r;
            n++;
            if (y2 != 0.0) {
                vec2 spoint = vec2(x3 / resolution.x, y2 / resolution.y * -1.0);
                average += texture2D(backbuffer, co  + spoint).r;
                n++;
            }
            x3 += sampleSize;   
        }
        y2 += sampleSize;    
    }
    return average / float(n);
}

//returns a point zoomed closer to the center of image
vec2 ZoomToCenter(vec2 currentpos, float zoomrate)
{
    //zoom method from here http://www.gamerendering.com/2008/12/20/radial-blur-filter/
    // 0.5,0.5 is the center of the screen
    // so substracting uv from it will result in
    // a vector pointing to the middle of the screen
    vec2 dir = 0.5 - currentpos; 
    // calculate the distance to the center of the screen
    float dist = sqrt(dir.x*dir.x + dir.y*dir.y); 
    // normalize the direction (reuse the distance)
    dir = dir/dist; 
    return currentpos+dir*zoomrate/resolution;
}

//returns a point zoomed closer to the mouse
vec2 ZoomToMouse(vec2 currentpos, float zoomrate)
{
    //zoom method from here http://www.gamerendering.com/2008/12/20/radial-blur-filter/
    vec2 dir = mouse - currentpos; 
    // calculate the distance to the center of the screen
    float dist = sqrt(dir.x*dir.x + dir.y*dir.y); 
    // normalize the direction (reuse the distance)
    dir = dir/dist; 
    return currentpos+dir*zoomrate/resolution;
}

void main( void ) 
{
    vec4 col = vec4(0.0);
    float activator = 0.0;
    float inhibitor = 0.0;
    
    if(length(mouse*resolution-gl_FragCoord.xy) < 30.0)
    {
        col=vec4(0.0);
        activator=0.0;
        inhibitor=0.0;
    } else {
        
        vec2 Delta = vec2(1.0)/resolution;
        vec2 uv = gl_FragCoord.xy / resolution;
        
        //vec2 position=ZoomToCenter(uv,1.5);
        vec2 position=ZoomToMouse(uv,1.12345);
        
        vec4 source = texture2D(backbuffer, position);
        float random = rand(vec2(position.x + time, position.y + time));
        vec4 colour = source + ((random * 2.0) - 1.0) * 0.1;

        //activator = averageForRadius(position, 3.0+1.0*sin(time));
        //inhibitor = averageForRadius(position, 10.0+5.0*cos(time));

        activator = averageForRadius(position, 2.0);
        inhibitor = averageForRadius(position, 15.0);
        
        
        if (activator > inhibitor) {
        colour += 0.05;
        } else {
        colour -= 0.05;
        } 
        
        col=colour;
    }

    glFragColor = vec4(col.r,inhibitor,activator,1.0);
}
