function qp_init(len,nmax,nid)
% qp_init(len,nmax,nid)
% Define global QP problem
%
% (Primal) min_{w,e}  .5*||w||^2 + sum_i e_i
%               s.t.   w*x_j >= b_j - e_i for j in Set_i, for all i
%
% (Dual)   max_{a}   -.5*sum_ij a_i(x_i*x_j)a_j + sum_i b_i*a_i
%               s.t.                  a_i >= 0
%                    sum_(j in Set_i) a_j <= 1
%
%   where w = sum_i a_i x_i
%
% qp.x(:,i) = x_i where size(qp.x) = [len nmax]
% qp.x(:,i) = id (of length nid) where vectors with same id belong to same Set S
% qp.b(i)   = b_i
% qp.d(i)   = ||x(i)||^2
% qp.a(i)   = a_i
% qp.w      = sum_i a_i x_i
% qp.l      = sum_i b_i a_i
% qp.n      = number of constraints
% qp.ub     = .5*||qp.w||^2 + C*sum_i e_i
% qp.lb     = -.5*sum_ij a_i(x_ix_j)a_j + sum_i b_i*a_i
% qp.svfix  = pointers to examples that are always kept in memory

global qp;
qp = [];
qp.x  = zeros(len,nmax,'single');
qp.i  = zeros(nid,nmax,'int32');
qp.b  = zeros(nmax,1,'single');
qp.d  = zeros(nmax,1,'double');
qp.a  = zeros(nmax,1,'double');
qp.sv = logical(zeros(1,nmax));  
qp.w  = zeros(len,1);
qp.l  = 0;
qp.n  = 0;
qp.ub = 0;
qp.lb = 0;
qp.svfix = [];