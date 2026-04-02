#version 420

// a reaction-diffusion substrate (@jatazak)

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec4 live = vec4(0.5,1.0,0.1,1.); // .b = .7

void main( void ) {
    const float n = 2.;
    
    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    vec2 pixel = 1./resolution;

    vec2 center = vec2(.5, .5);
    float r = length(mouse - center);
    float th = atan(mouse.y - center.y, mouse.x - center.x);

    bool done = false;
    float tau = 6.28318;
    for (float k = 0.; k < n; ++k) { // for each forcing circle
        
        vec2 relative = position - (center + r * vec2(cos(th + tau*k/n), sin(th + tau*k/n)));
        float d = length(relative);
        if (d > 0.3 && d < 0.302) {
            float p = 1. / (100.*(d-.2) + 1.); // fast falloff at outer edge (TODO: diagnose lag)
            glFragColor = live * p + texture2D(backbuffer, position) * (1.-p); // blend with transparency
            done = true;
        }
    }
        
    const float autocat = .55, autoinh = .05, hetinh = .1, decay = .1, hetcat = 1.1;
    if (!done) {
        vec4 sum = vec4(0., 0., 0., 1.);
        sum += 2.*texture2D(backbuffer, position + pixel * vec2(-1., 0.));
        sum += 2.*texture2D(backbuffer, position + pixel * vec2(1., 0.));
        sum += 2.*texture2D(backbuffer, position + pixel * vec2(0., -1.));
        sum += 2.*texture2D(backbuffer, position + pixel * vec2(0., 1.));

        sum += texture2D(backbuffer, position + pixel * vec2(-1., -1.));
        sum += texture2D(backbuffer, position + pixel * vec2(-1., 1.));
        sum += texture2D(backbuffer, position + pixel * vec2(1., -1.));
        sum += texture2D(backbuffer, position + pixel * vec2(1., 1.));
        
        vec4 me = texture2D(backbuffer, position);
        sum -= 8.*me;
        sum /= 8.;

            // parameter sweep
            float localcat = autocat + .1*(1.-position.x); // boost autocatalysis on left edge
            float neighinh = hetinh + .3*(1.-position.y);

        me.r -= .02*me.r;
        // a gradient: autocat = .6, autoinh = .2, hetinh = .1, decay = .1, hetcat = .9;
        me.g = sum.g + me.g * (localcat - autoinh * me.g - neighinh * me.b);
        me.b = sum.b - decay + hetcat * me.g;

            // me.g = sum.g + me.g * (localcat * me.g - hetinh * me.b) / (me.b*me.b + me.g*me.g) - decay;
            // me.b = .1*sum.b + me.b * (hetcat * me.g) / (me.b*me.b + me.g*me.g) - .1*decay;
        
        // me.g = sum.g; // DEBUG: diffusion alone
        // me.b = sum.b;
        
        // me.g += me.g * 1. - .5 * me.g*me.g - .4 * me.b;
        // me.b += sum.b * .1 + .1 * me.g; //  me.b * (1. - me.b);
        
        // me.g = sum.g * (1.4 - .1 * me.g) - .4 * me.b;
        // me.b = sum.b * .9 + .1 * me.g;
        
        glFragColor = me; // vec4(r, g, b, 1.);
    }
}
