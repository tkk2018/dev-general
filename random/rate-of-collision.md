## Introduction

In this study, we analyze the collision rates of random string using pattern `[a-zA-Z0-9]{8}`, resulting in a total of 218,340,105,584,896 possible combinations. However, as the number of generated strings increases, the likelihood of collisions (two identical strings) also rises. In this report, we explore collision probabilities and propose preventive measures.

## Collision Probability Calculation

1\. Collision Probability at 50% (n):

We aim to find the number of generated strings (n) at which the collision probability reaches 50%. Using the birthday paradox concept, we approximate:

$$
n≈\sqrt{m​}
$$

where:

* (m) represents the total number of combinations (62^8).
* (n) is the threshold for a 50% collision probability.

Solving for (n), we get (n $\approx$ 14,776,336).

2\. Time to Reach 50% Collision:

Assuming we create (x) records per day, we calculate the time (in years) to reach (n):

$$
days = \frac{n}{x \times 365}
$$

For (x = 21), it would take approximately 1,927 years to reach a 50% collision rate.

## Early Prevention

Waiting until a 50% collision rate is too late. To prevent collisions, we should act before reaching that threshold.

Let’s consider a desired collision rate of 2% (y).

We solve for the time required to reach 2% collisions:

$$
days = \frac{1927 \times y}{50}
$$

For 2% collisions, it would take approximately 77 years.

## Solution

The solution is simple, just add one more character (pattern: `[a-zA-Z0-9]{9}`).

## Reference

* https://en.wikipedia.org/wiki/Birthday_problem#Square_approximation
* https://brilliant.org/wiki/birthday-paradox/
* https://stackoverflow.com/a/41156/16027098
