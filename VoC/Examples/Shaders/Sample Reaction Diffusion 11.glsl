#version 420

// absurd reaction-diffusion (@jasminumlutris)

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec4 live = vec4(0.5,1.0,0.7,1.);
vec4 dead = vec4(0.,0.,0.,1.);

void main( void ) {
    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    vec2 pixel = 1./resolution;

    vec2 center = vec2(.5, .5);
    float r = length(mouse - center);
    float th = atan(mouse.y - center.y, mouse.x - center.x);

    bool done = false;
    float tau = 6.28318;
    for (float k = 0.; k < 6.; ++k) {
        
        vec2 relative = position - (center + r * vec2(cos(th + tau*k/6.), sin(th + tau*k/6.)));
        if (length(relative) > 0.035 && length(relative) < 0.04) {
            glFragColor = live;
            done = true;
        }
    }
        
    if (!done) {
        vec4 sum = dead;
        sum += 2.*texture2D(backbuffer, position + pixel * vec2(-1., 0.));
        sum += 2.*texture2D(backbuffer, position + pixel * vec2(1., 0.));
        sum += 2.*texture2D(backbuffer, position + pixel * vec2(0., -1.));
        sum += 2.*texture2D(backbuffer, position + pixel * vec2(0., 1.));

        sum += texture2D(backbuffer, position + pixel * vec2(-1., -1.));
        sum += texture2D(backbuffer, position + pixel * vec2(-1., 1.));
        sum += texture2D(backbuffer, position + pixel * vec2(1., -1.));
        sum += texture2D(backbuffer, position + pixel * vec2(1., 1.));
        sum /= 12.;
        vec4 me = texture2D(backbuffer, position);

        float r, g, b = 0.;
        r = sum.r;
        g = sum.g * (1.4 - .1 * me.g) - .4 * me.b;
        b = sum.b * .9 + .1 * me.g; //  me.b * (1. - me.b);
        
                       // + .2 * texture2D(ppixels, position + pixel * vec2(0., 1.));
        
        glFragColor = vec4(.98*r, g, b, 1.);
    }
}
