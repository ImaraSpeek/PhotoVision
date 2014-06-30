function qp_mult(tol,iter)
% qp_mult(tol,iter)
% Optimize QP until increase of dual is below 'tol'

global qp;

if nargin < 1,
  tol = .001;
end

if nargin < 2,
 iter = 1000;
end

% Recompute qp.w in case of numerical precision issues
qp_refresh();
fprintf('\n LB=%.4f [',qp.lb);

% Iteratively apply coordinate descent, pruning active set (support vectors)
% If we've not improving dual for active set
% 1) Try to reinitialize active set to full cache
% 2) If we just did (1), we can't improve dual anymore so stop

lb = -inf;
qp.sv(1:qp.n) = 1;
for t = 1:iter,
  init = all(qp.sv(1:qp.n));
  qp_one();
  fprintf('.');
  if lb > 0 && ((qp.lb - lb)/qp.lb < tol),
    if init,
      break;
    end
    qp.sv(1:qp.n) = 1;
  end
  lb = qp.lb;
  %fprintf('%.4f',lb);
end
fprintf('] LB=%.4f',qp.lb);
