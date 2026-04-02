#version 420

// original https://www.shadertoy.com/view/7sG3Dc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi acos(-1.0)

void main(void)
{
    /* control parameters */
    vec3 color, acu_color = vec3(0.);
    vec2 uv,ab;
    float alpha, angle, count = 0.; 
    float twist = 3., speed = -2.; // spiral
    float aa_step = .1, aa = 1.; // anti-alias
    for (float i=-aa;i<=aa;i+=aa_step)
        for (float j=-aa;j<=aa;j+=aa_step)
    {
        uv = (gl_FragCoord.xy + vec2(i,j))/resolution.y - vec2(resolution.x*.5/resolution.y, .5);
        ab = vec2(cos(speed*time+twist*length(uv)), sin(speed*time+twist*length(uv)));
        angle = atan(cross(vec3(uv,0.),vec3(ab,0.)).z/dot(uv,ab));
        angle = (angle/pi + .5)*180.;
        if (cross(vec3(uv,0.),vec3(ab,0.)).z < 0.)
            angle += 180.;
        if (angle < 30.)
           color = vec3(0.,0.,1.);
        else if (angle < 90.)
           color = vec3(1.,0.,1.);
        else if (angle < 150.)
           color = vec3(0.,1.,1.);
        else if (angle < 180.0)
           color = vec3(0.,0.,1.);
        else if (angle < 210.0)
           color = vec3(1.,1.,0.);
        else if (angle < 270.)
           color = vec3(0.,1.,0.);
        else if (angle < 330.)
           color = vec3(1.,0.,0.);
        else
           color = vec3(1.,1.,0.);
        alpha = smoothstep(0.95,1.0,length(uv)/0.45);
        color = vec3(.2)*alpha + color*(1.-alpha);
        acu_color = acu_color + color;
        count += 1.;
    }
    // Output to screen
    glFragColor = vec4(acu_color*1.0/pow((2.*aa)*1./aa_step,2.),1.0);
}
